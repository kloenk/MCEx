defmodule MCEx.MC.Response do
  alias MCEx.MC.Packet
  require Logger

  def create_response(state, data, serverbound \\ false)

  def create_response(state, {:handshake}, _serverbound) do
    IO.puts("state: #{inspect state}")
    # TODO: config element
    version = "1.15.2"
    protocol = Map.get(state, "protocol", 578)
    max_players = 9999999

    on_players = 999999999 # TODO: fetch data form 'ring'
    # TODO: fetch sample somewhere
    sample = [%{"name" => "thinkofdeath", "id" => "4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]

    # TODO: fetch description
    description = "Hello World from Elixir on #{Map.get(state, "address", "ERROR")}"

    json = %{"version" => %{"name" => version, "protocol" => protocol},
             "players" => %{"max" => max_players, "online" => on_players, "sample" => sample},
             "description" => %{"text" => description}}

    json = Jason.encode!(json)
    json_size = div(bit_size(json), 8)
    #IO.puts("size: #{json_size}")
    json_size = Packet.to_varInt(json_size)
    #IO.inspect("json: #{inspect json_size}")
    resp = << 0x00,  json_size::binary, json::binary >>
    size = div(bit_size(resp), 8)
    size = Packet.to_varInt(size)

    <<size::binary, resp::binary>>
  end
  def create_response(_state, {:ping, payload}, _serverbound) when is_binary(payload) do
    msg = << 0x01, payload::binary >>
    size = div(bit_size(msg), 8)
    size = Packet.to_varInt(size)

    <<size::binary, msg::binary>>
  end

  def create_response(_state, data, _serverbound) do
    Logger.warn("cannot create response for #{inspect(data)}")
    <<>>
  end

end
