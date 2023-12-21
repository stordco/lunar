defmodule Luau.RuntimeTest do
  use ExUnit.Case

  alias Luau.Runtime

  defmodule BarLibrary do
    use Luau.Library, scope: "bar"
  end

  defmodule FooLibrary do
    use Luau.Library, scope: "foo"
  end

  describe "initialize/0" do
    test "returns a runtime containing the Lua state and unique id" do
      assert %Runtime{id: id, state: state} = Runtime.initialize()
      assert is_binary(id)
      refute is_nil(state)
    end
  end

  describe "initialize/1" do
    test "accepts `:libraries` as an option" do
      assert %Runtime{libraries: [BarLibrary]} = Runtime.initialize(libraries: [BarLibrary])
    end

    test "accepts `:variables` as an option" do
      assert %Runtime{} = Runtime.initialize(variables: %{name: "Robert"})
    end
  end

  describe "set_variable/3" do
    setup do
      runtime = Runtime.initialize()

      {:ok, runtime: runtime}
    end

    test "sets a variable", %{runtime: runtime} do
      name = "name"
      value = "Robert"

      assert %Runtime{variables: %{^name => ^value}} = Runtime.set_variable(runtime, name, value)
    end
  end

  describe "add_library/2" do
    setup do
      runtime = Runtime.initialize()

      {:ok, runtime: runtime}
    end

    test "adds a library to the lua runtime", %{runtime: runtime} do
      assert %Runtime{libraries: [FooLibrary, BarLibrary]} =
               runtime
               |> Runtime.add_library(BarLibrary)
               |> Runtime.add_library(FooLibrary)
    end
  end
end
