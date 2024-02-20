defmodule Test2.Supervisor do
  @batches 100

  def do_start(0, _sup), do: []

  def do_start(n, sup) do
    IO.puts("STARTING #{n}")

    for _i <- 0..@batches do
      DynamicSupervisor.start_child(
        sup,
        Supervisor.child_spec(
          {Test2,
           uri: "wss://localhost:4443/socket/websocket",
           mint_opts: [transport_opts: [verify: :verify_none], protocols: [:http1]]},
          id: make_ref()
        )
      )
    end

    Process.sleep(1000)
    do_start(n - @batches, sup)
  end
end
