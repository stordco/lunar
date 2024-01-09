defmodule Luau.RuntimeTest do
  use ExUnit.Case

  alias Luau.Runtime

  defmodule AdderLibrary do
    use Luau.Library, scope: "Adder"

    deflua add(a, b) do
      a + b
    end
  end

  defmodule EvenLibrary do
    use Luau.Library, scope: "Even"

    deflua is_even(value) do
      rem(value, 2) == 0
    end
  end

  describe "init/0" do
    test "returns a runtime containing the Lua state and unique id" do
      assert %Runtime{id: id, state: state} = Runtime.init()
      assert is_binary(id)
      refute is_nil(state)
    end
  end

  describe "set_variable/3" do
    setup do
      {:ok, runtime: Runtime.init()}
    end

    test "sets a variable", %{runtime: runtime} do
      name = ["name"]
      value = "Robert"
      assert {:ok, %Runtime{variables: %{^name => ^value}}} = Runtime.set_variable(runtime, name, value)
    end

    test "wraps variable path as necessary", %{runtime: runtime} do
      name = "name"
      value = "Robert"

      assert {:ok, %Runtime{variables: %{[^name] => ^value}}} = Runtime.set_variable(runtime, name, value)
    end
  end

  describe "load_module!/2" do
    setup do
      {:ok, runtime: Runtime.init()}
    end

    test "load a Luau.Library to the lua runtime", %{runtime: runtime} do
      assert %Runtime{modules: [EvenLibrary, AdderLibrary]} =
               loaded_runtime = runtime |> Runtime.load_module!(AdderLibrary) |> Runtime.load_module!(EvenLibrary)

      script = """
      local a = Adder.add(3,3)
      local b = Even.is_even(a)
      return b
      """

      assert {:ok, [true], _runtime} = Runtime.run(loaded_runtime, script)
    end
  end

  describe "load_lua!/2" do
    setup do
      {:ok, runtime: Runtime.init()}
    end

    test "loads simple lua script into runtime", %{runtime: runtime} do
      path = Path.join([__DIR__, "support", "hello.lua"])
      assert %Runtime{lua: [^path]} = loaded_runtime = Runtime.load_lua!(runtime, path)

      script = """
      return hello("Robert")
      """

      assert {:ok, ["Hello Robert!"], _runtime} = Runtime.run(loaded_runtime, script)
    end
  end
end
