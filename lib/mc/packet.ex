defmodule MCEx.MC.Packet do

  @doc """
  read a var Int from a binary string
  """
  @spec read_varInt(bitstring()) :: {integer(), binary()}
  def read_varInt(size) when is_binary(size) do
    <<size::1, value::7, data::binary>> = size
    case size do
      1 -> read_varInt(<<value::7>>, data)
      0 -> {var_toint(value), data}
    end
  end
  @spec read_varInt(bitstring(), binary()) :: {integer(), binary()}
  def read_varInt(value, data) when is_bitstring(value) and is_binary(data) do
    <<size::1, add::7, data::binary>> = data
    value = << value::bitstring, add::7 >>
    IO.inspect(value)
    case size do
      1 -> read_varInt(value, data)
      0 -> {var_toint(value), data}
    end
  end



  #convert the bitstring to int (also usable for long)
  @spec var_toint(bitstring()) :: integer()
  defp var_toint(data) when is_bitstring(data) do
    size = div(bit_size(data), 7)
    <<int::size(size)-unit(7)-signed-little>> = data # TODO: make signed
    int
  end
  @spec var_toint(integer()) :: integer()
  defp var_toint(int) when is_integer(int) do
    var_toint(<<int::7>>)
  end

end
