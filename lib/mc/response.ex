defmodule MCEx.MC.Response do
  alias MCEx.MC.Packet
  require Logger

  def create_response(state, data, serverbound \\ false)

  def create_response(state, {:handshake}, _serverbound) do
    config = Application.get_env(:mcex, String.to_atom(Map.get(state, "address", "default")), Application.get_env(:mcex, :default))
    # TODO: config element
    version = "1.15.2" # FIXME: derivate from protocol number
    protocol = Map.get(state, "protocol", 578)
    max_players = config[:max_players]

    on_players = 999999999 # TODO: fetch data form 'ring'
    # TODO: fetch sample somewhere
    sample = [%{"name" => "thinkofdeath", "id" => "4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]

    description = config[:motd]
    description = Regex.replace(~r/%address%/, description, Map.get(state, "address"))
    description = Regex.replace(~r/%port%/, description, Integer.to_string(Map.get(state, "port")))

    json = %{"version" => %{"name" => version, "protocol" => protocol},
             "players" => %{"max" => max_players, "online" => on_players, "sample" => sample},
             "description" => %{"text" => description}}

    json = Jason.encode!(json)
    json_size = div(bit_size(json), 8)
    json_size = Packet.to_varInt(json_size)
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
