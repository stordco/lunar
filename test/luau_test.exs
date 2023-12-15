defmodule LuauTest do
  use ExUnit.Case
  doctest Luau

  test "greets the world" do
    assert Luau.hello() == :world
  end
end
