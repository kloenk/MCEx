defmodule MCEx.Server do
  alias MCEx.MC.Packet
  alias MCEx.MC.Parse
  alias MCEx.MC.Response
  alias :gen_tcp ,as: GenTcp
  require Logger

  def accept(port) do
    {:ok, sochet} = GenTcp.listen(port, [:binary, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(sochet)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = GenTcp.accept(socket)
    {:ok, pid} = Task.Supervisor.start_child(MCEx.TaskSupervisor, fn -> serve(client, {[], <<>>}, %{}) end)
    :ok = GenTcp.controlling_process(client, pid)
    loop_acceptor(socket)
  end

  defp serve(socket, {packages, bin}, state) when is_binary(bin) do
    {packages, bin} = socket
    |> read_line(bin)

    {packages, state} = parse(packages, [], state)
    responde(packages, socket, state)

    serve(socket, {packages, bin}, state)
  end

  defp parse([data | rest], packets, state) when is_binary(data) and is_list(packets) do
    packet = Parse.parse(data)

    state = addToState(state, packet)

    packets = packets ++ [packet]

    parse(rest, packets, state)
  end

  defp parse([], packets, state) do
    {packets, state}
  end

  defp responde([packet | rest], socket, state) do
    response = Response.create_response(state, packet)

    write_line(response, socket)
    responde(rest, socket, state)
  end

  defp responde([], _socket, state) when is_map(state) do
  end

  defp read_line(socket, bin) when is_binary(bin) do
    {:ok, data} = GenTcp.recv(socket, 0)
    bin = bin <> data
    {packages, bin} = Packet.split(bin)
    IO.inspect(packages)
    {packages, bin}
  end

  defp write_line(line, socket) do
    Logger.info("writing: #{inspect line}")
    GenTcp.send(socket, line)
  end

  defp addToState(state, {:handshake, {protocol_version, server_address, server_port, _next_state}}) when is_map(state) do
    state
    |> Map.put("protocol", protocol_version)
    |> Map.put("address", server_address)
    |> Map.put("port", server_port)
  end
  defp addToState(state, packet) when is_map(state) and is_tuple(packet) do
    state
  end
end
