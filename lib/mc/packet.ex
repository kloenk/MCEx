defmodule MCEx.MC.Packet do
  use Bitwise, only_operators: true

  @doc """
  read a var Int from a binary string

  # TODO: add test if longer than 5 bytes
  """
  @spec read_varInt(bitstring()) :: {integer(), binary()}
  def read_varInt(data) when is_binary(data) do
    <<size::1, value::7, data::binary>> = data

    case size do
      1 -> read_varInt(<<value::7>>, data)
      0 -> {var_toint(value), data}
    end
  end

  @spec read_varInt(bitstring(), binary()) :: {integer(), binary()}
  def read_varInt(value, data) when is_bitstring(value) and is_binary(data) do
    <<size::1, add::7, data::binary>> = data
    value = <<add::7, value::bitstring>>

    case size do
      1 -> read_varInt(value, data)
      0 -> {var_toint(value), data}
    end
  end

  @spec read_string(binary()) :: {binary(), binary()}
  def read_string(data) when is_binary(data) do
    {size, data} = read_varInt(data)
    <<value::binary-size(size), data::binary>> = data
    {value, data}
  end

  def read_uShort(data) when is_binary(data) do
    <<value::size(2)-unit(8)-unsigned-big, rest::binary>> = data
    {value, rest}
  end

  @spec split(binary()) :: {[binary()], binary()} | {[], binary()}
  def split(data) when is_binary(data) do
    if bit_size(data) < 8 do
      {[], data}
    else
      {size, data} = read_varInt(data)

      case data do
        # {[data], rest}
        <<data::binary-size(size), rest::binary>> -> split([data], rest)
        _ -> {[], data}
      end
    end
  end

  @spec split([binary()], binary()) :: {[binary()], binary()}
  def split(data, rest) when is_list(data) and is_binary(rest) do
    if bit_size(rest) < 8 do
      {data, rest}
    else
      {size, rest} = read_varInt(rest)

      case rest do
        <<value::binary-size(size), rest::binary>> -> split(data ++ [value], rest)
        _ -> {data, rest}
      end
    end
  end

  @doc """
  convert an integer to an varInt minecraft data type
  """
  @spec to_varInt(integer()) :: binary()
  def to_varInt(value) when is_integer(value) do
    temp = value &&& 0b01111111
    value = value >>> 7

    temp =
      if value != 0 do
        temp ||| 0b10000000
      else
        temp
      end

    cond do
      value != 0 -> to_varInt(value, <<temp::8>>)
      value == 0 -> <<temp::8>>
    end
  end

  @doc """
  convert integer to an varInt minecraft data type.
  This funtcion takes an old temp data and appends the data to it
  """
  @spec to_varInt(integer(), binary()) :: binary()
  def to_varInt(value, temp_old) when is_integer(value) and is_binary(temp_old) do
    temp = value &&& 0b01111111
    value = value >>> 7

    temp =
      if value != 0 do
        temp ||| 0b10000000
      else
        temp
      end

    cond do
      value != 0 -> to_varInt(value, <<temp_old::binary, temp::8>>)
      value == 0 -> <<temp_old::binary, temp::8>>
    end
  end

  @doc """
  converts a String into an mineccraft string type
  """
  @spec to_string(binary()) :: binary()
  def to_string(str) when is_binary(str) do
    size = div(bit_size(str), 8)
    size = to_varInt(size)

    <<size::binary, str::binary>>
  end

  @doc """
  adds the size of the package to the front of the package, so minecraft can read it.
  see https://wiki.vg/Protocol#Packet_format
  """
  @spec make_packet(binary()) :: binary()
  def make_packet(packet) when is_binary(packet),
    do: <<to_varInt(div(bit_size(packet), 8))::binary, packet::binary>>

  @doc """
  creates a packet from the packet id and the given payload
  """
  @spec make_packet(integer(), binary()) :: binary()
  def make_packet(id, payload) when is_integer(id) and is_binary(payload),
    do: make_packet(<<id::integer, payload::binary>>)

  @doc """
  creates a packet from the packet id and the given payload and compresses it
  if it is bigger than the threshould
  """
  @spec make_packet(integer(), binary(), integer()) :: binary()
  def make_packet(id, payload, threshould) do
    payload = <<id::integer, payload::binary>>
    # |> to_varInt()
    payload_size = div(bit_size(payload), 8)

    payload =
      if payload_size >= threshould do
        payload = :zlib.compress(payload)
        <<to_varInt(payload_size)::binary, payload::binary>>
      else
        <<0, payload::binary>>
      end

    make_packet(payload)
  end

  # convert the bitstring to int (also usable for long)
  @spec var_toint(bitstring()) :: integer()
  defp var_toint(data) when is_bitstring(data) do
    size = div(bit_size(data), 7)
    # TODO: make signed
    <<int::size(size)-unit(7)-signed-big>> = data
    int
  end

  @spec var_toint(integer()) :: byte()
  defp var_toint(int) when is_integer(int) do
    var_toint(<<int::7>>)
  end
end
