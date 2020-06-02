defmodule MCEx.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, args) do
    port = 25566

    children = [
      {Task.Supervisor, name: MCEx.TaskSupervisor},
      Supervisor.child_spec({Task, fn -> MCEx.Server.accept(port) end}, restart: :permanent)
      # Starts a worker by calling: MCEx.Worker.start_link(arg)
      # {SshCollector.Worker, arg}
    ] ++ gen_server_list()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MCEx.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def gen_server_list() do
    servers = Application.get_all_env(:mcex)

    gen_server_list(servers, %{})
  end

  def gen_server_list([{_name, config} | rest ], servers) do
    name = config[:server]

    # {MCEx.Server.Store, [name: name]}
    servers = Map.put(servers, name, Supervisor.child_spec({MCEx.Server.Store, [name: name]}, id: name))
    gen_server_list(rest, servers)
    #[Supervisor.child_spec({MCEx.Server.Store, [name: name]}, id: name)] ++ gen_server_list(rest)
  end

  def gen_server_list([], servers) do
    servers
    |> Map.to_list()
    |> server_to_list()
  end

  def server_to_list([{_name, config} | rest]), do: [config] ++ server_to_list(rest)

  def server_to_list([]), do: []
end
