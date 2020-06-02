defmodule MCEx.MC.Response do
  alias MCEx.MC.Packet
  require Logger

  def create_response(state, data, serverbound \\ false)

  def create_response(state, {:handshake}, _serverbound) do
    config =
      Application.get_env(
        :mcex,
        String.to_atom(Map.get(state, "address", "default")),
        Application.get_env(:mcex, :default)
      )

    # TODO: config element
    # FIXME: derivate from protocol number
    version = "1.15.2"
    protocol = Map.get(state, "protocol", 578)
    max_players = config[:max_players]

    # TODO: fetch data form 'ring'
    on_players = 999_999_999
    # TODO: fetch sample somewhere
    sample = [%{"name" => "thinkofdeath", "id" => "4566e69f-c907-48ee-8d71-d7ba5aa00d20"}]

    description = config[:motd]
    description = Regex.replace(~r/%address%/, description, Map.get(state, "address"))

    description =
      Regex.replace(~r/%port%/, description, Integer.to_string(Map.get(state, "port")))

    json = %{
      "version" => %{"name" => version, "protocol" => protocol},
      "players" => %{"max" => max_players, "online" => on_players, "sample" => sample},
      "description" => %{"text" => description}
    }

    json = Jason.encode!(json)
    json = Packet.to_string(json)

    Packet.make_packet(<<0x00, json::binary>>)
  end

  def create_response(_state, {:handshake, {_protocol, _host, _port, _next_state}}, _serverbound) do
    <<>>
  end

  def create_response(state, {:handshake, {name}}, _serverbound) when is_binary(name) do
    # FIXME: encryption foo

    # uuid = "\"c16d92b1eca1438793de4f27de56ff03\""
    uuid = Map.get(state, "uuid")
    uuid = Packet.to_string(uuid)

    # username = "kloenk"
    username = Map.get(state, "username")
    username = Packet.to_string(username)

    Packet.make_packet(<<0x02, uuid::binary, username::binary>>)
  end

  def create_response(_state, {:ping, payload}, _serverbound) when is_binary(payload),
    do: Packet.make_packet(<<0x01, payload::binary>>)

  def create_response(_state, data, _serverbound) do
    Logger.warn("cannot create response for #{inspect(data)}")
    <<>>
  end
end
