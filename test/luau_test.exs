defmodule LuauTest do
  use ExUnit.Case

  defmodule TestLibrary do
    @moduledoc """
    A test library for Luau.
    """
    use Luau.Library, scope: "test"

    deflua hello(name) do
      "Hello, #{name}!"
    end
  end

  describe "init/0" do
    test "returns a runtime" do
      assert %Luau.Runtime{} = Luau.init()
    end
  end

  describe "execute/2" do
    test "evaluates Lua" do
      #      runtime = Luau.initialize(libraries: [TestLibrary], variables: %{name: "Robert"})
      #      assert {"Hello, Robert!", %Luau.Runtime{}} = Luau.execute(runtime, ~s/test.hello(name)/)
    end
  end
end
