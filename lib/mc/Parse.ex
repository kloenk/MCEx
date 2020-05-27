defmodule MCEx.MC.Parse do
  alias MCEx.MC.Packet
  require Logger

  def parse(data, serverbound \\ true)
  #@spec()
  def parse(<<0, rest::binary>>, true) when bit_size(rest) == 0 do
    {:handshake}
  end
  def parse(<<0, rest::binary>>, _serverbound) when is_binary(rest) do
    {protocol_version, rest} = Packet.read_varInt(rest)
    {server_address, rest} = Packet.read_string(rest)
    {server_port, rest} = Packet.read_uShort(rest)
    {next_state, _rest} = Packet.read_varInt(rest)

    {:handshake, {protocol_version, server_address, server_port, next_state}}
  end
  def parse(<<1, rest::binary>>, _serverbound) when is_binary(rest) do
    {:ping, rest}
  end



  # Unknown packet catcher
  def parse(data, _serverbound) when is_binary(data) do
    Logger.warn("unknown data: #{inspect(data)}")
    {:unknown}
  end

end
