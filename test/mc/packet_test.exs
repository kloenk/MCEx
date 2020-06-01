defmodule MCEx.MC.PacketTest do
  use ExUnit.Case
  alias MCEx.MC.Packet

  doctest MCEx.MC.Packet

  describe "varInt" do
    test "read one value" do
      {value, rest} = Packet.read_varInt(<<8::8>>)
      assert value == 8
      assert rest == <<>>

      {value, rest} = Packet.read_varInt(<<32::8, 7::8>>)
      assert value == 32
      assert rest == <<7::8>>
    end

    test "read 2 value" do
      {value, rest} = Packet.read_varInt(<<0xFF, 0x01>>)
      assert value == 255
      assert rest == <<>>

      {value, rest} = Packet.read_varInt(<<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>)
      assert value == -1
      assert rest == <<>>

      {value, rest} = Packet.read_varInt(<<0xFF, 0xFF, 0xFF, 0xFF, 0x7F>>)
      assert value == -1
      assert rest == <<>>
    end

    # TODO: add tests for longer instances
  end
end
