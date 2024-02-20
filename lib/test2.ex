defmodule Test2 do
  @moduledoc """
  A socket client for connecting to that other Phoenix server

  Periodically sends pings and asks the other server for its metrics.
  """

  use Slipstream

  require Logger

  @topic "room:foo"

  def start_link(args) do
    Slipstream.start_link(__MODULE__, args)
  end

  @impl Slipstream
  def init(config) do
    {:ok, connect!(config), {:continue, :start_ping}}
  end

  @impl Slipstream
  def handle_continue(:start_ping, socket) do
    timer = :timer.send_interval(15000, self(), :do_ping)

    {:noreply, assign(socket, :ping_timer, timer)}
  end

  @impl Slipstream
  def handle_connect(socket) do
    {:ok, join(socket, @topic)}
  end

  @impl Slipstream
  def handle_join(@topic, _join_response, socket) do
    {:ok, socket}
  end

  @impl Slipstream
  def handle_info(:do_ping, socket) do
    # we will asynchronously receive a reply and handle it in the
    # handle_reply/3 implementation below
    {:ok, ref} = push(socket, @topic, "ping", %{})

    {:noreply, assign(socket, :ping_ref, ref)}
  end

  @impl Slipstream
  def handle_reply(ref, {:ok, "pong"}, socket) do
    if ref != socket.assigns.ping_ref do
      IO.puts("Out of order")
    end

    {:ok, socket}
  end

  @impl Slipstream
  def handle_message(@topic, event, message, socket) do
    Logger.error(
      "Was not expecting a push from the server. Heard: " <>
        inspect({@topic, event, message})
    )

    {:ok, socket}
  end

  @impl Slipstream
  def handle_disconnect(_reason, socket) do
    :timer.cancel(socket.assigns.ping_timer)

    {:stop, :normal, socket}
  end

  @impl Slipstream
  def terminate(_reason, socket) do
    IO.puts("TERMAINTING")
    disconnect(socket)
  end
end
