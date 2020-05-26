defmodule MCEx.Server do
  alias MCEx.MC.Packet
  alias :gen_tcp ,as: GenTcp
  require Logger

  def accept(port) do
    {:ok, sochet} = GenTcp.listen(port, [:binary, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(sochet)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = GenTcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(MCEx.TaskSupervisor, fn -> serve(client, <<>>) end)
    :ok = GenTcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket, bin) when is_binary(bin) do
    bin = socket
    |> read_line(bin)


    serve(socket, bin)
  end

  defp read_line(socket, bin) when is_binary(bin) do
    {:ok, data} = GenTcp.recv(socket, 0)
    bin = bin <> data
    {packages, bin} = Packet.split(bin)
    IO.inspect(packages)
    bin
  end

  defp write_line(line, socket) do
    GenTcp.send(socket, line)
  end
end
