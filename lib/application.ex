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
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MCEx.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
