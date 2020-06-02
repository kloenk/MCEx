defmodule MCEx.MC.Parse do
  alias MCEx.MC.Packet
  require Logger

  # FIXME: legacy ping packet

  def parse(data, serverbound \\ true)
  # @spec()
  def parse(<<0, rest::binary>>, true) when bit_size(rest) == 0 do
    {:handshake}
  end

  def parse(<<0, rest::binary>>, true) when is_binary(rest) do
    {protocol_version, _bin} = Packet.read_varInt(rest)

    case protocol_version do
      x when x <= 16 -> parse_handshake_name(rest)
      _ -> parse_handshake(rest)
    end
  end

  def parse(<<1, rest::binary>>, true) when is_binary(rest) do
    {:ping, rest}
  end

  # Unknown packet catcher
  def parse(data, _serverbound) when is_binary(data) do
    Logger.warn("unknown data: #{inspect(data)}")
    {:unknown}
  end

  defp parse_handshake_name(rest) when is_binary(rest) do
    {name, _rest} = Packet.read_string(rest)

    {:handshake, {name}}
  end

  defp parse_handshake(rest) when is_binary(rest) do
    {protocol_version, rest} = Packet.read_varInt(rest)
    {server_address, rest} = Packet.read_string(rest)
    {server_port, rest} = Packet.read_uShort(rest)
    {next_state, _rest} = Packet.read_varInt(rest)

    next_state =
      case next_state do
        1 -> :status
        2 -> :login
      end

    {:handshake, {protocol_version, server_address, server_port, next_state}}
  end
end
