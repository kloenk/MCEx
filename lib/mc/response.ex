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
    #on_players = 999_999_999
    on_players = MCEx.Server.Store.get_user_count(config[:server])
    sample = MCEx.Server.Store.get_user(config[:server], 3) # get 3 samples

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

    Packet.make_packet(0x00, json)
  end

  def create_response(_state, {:handshake, {_protocol, _host, _port, _next_state}}, _serverbound) do
    <<>>
  end

  def create_response(state, {:handshake, {name}}, _serverbound) when is_binary(name) do
    # FIXME: encryption foo

    uuid = Map.get(state, "uuid")
    uuid = Packet.to_string(uuid)

    # username = "kloenk"
    username = Map.get(state, "username")
    username = Packet.to_string(username)

    Logger.info("player #{name} logged in")

    Packet.make_packet(0x02, uuid <> username)
  end

  #{:add_user, [{"Kloenk", "c16d92b1-eca1-4387-93de-4f27de56ff03"}]}
  def create_response(state, {:add_user, users}, _serverbound) when is_list(users) do
    users_num = length(users)
    users = create_new_user_list(users)

    Packet.make_packet(0x34, Packet.to_varInt(0) <> Packet.to_varInt(users_num) <> users)
  end

  def create_response(_state, {:ping, payload}, _serverbound) when is_binary(payload),
    do: Packet.make_packet(0x01, payload)

  def create_response(_state, data, _serverbound) do
    Logger.warn("cannot create response for #{inspect(data)}")
    <<>>
  end

# {"Kloenk", "c16d92b1-eca1-4387-93de-4f27de56ff03"}
  #defp create_new_user_list([{username, uuid} | rest]) do
  #  #Logger.warn("user_format: #{inspect user}")
  #  uuid = UUID.string_to_binary!(uuid) |> :binary.decode_unsigned()
  #  uuid = <<uuid::size(8)-unit(16)>>
  #  name = Packet.to_string(username)

  #  properties_num = Packet.to_varInt(0)

  #  gamemode = Packet.to_varInt(1)
  #  ping = Packet.to_varInt(500) # TODO: do ping magic

  #  display_name? = <<0x00>>


  #  <<>>
  #end
  defp create_new_user_list(list) when is_list(list) do
    list
    |> Stream.map(&map_user(&1))
    |> Enum.into(<<>>)
  end

  defp map_user({username, uuid}) do
    uuid = UUID.string_to_binary!(uuid)
    name = Packet.to_string(username)

    properties_num = Packet.to_varInt(0)

    gamemode = Packet.to_varInt(1)
    ping = Packet.to_varInt(500) # TODO: do ping magic

    display_name? = <<0x00>>

    uuid <> name <> properties_num <> gamemode <> ping <> display_name?
  end
end
