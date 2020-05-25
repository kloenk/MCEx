defmodule MCExTest do
  use ExUnit.Case
  doctest MCEx

  test "greets the world" do
    assert MCEx.hello() == :world
  end
end
