defmodule LuauTest do
  use ExUnit.Case

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
    test "returns a luau containing the Lua state and unique id" do
      assert %Luau{id: id, state: state} = Luau.init()
      assert is_binary(id)
      refute is_nil(state)
    end
  end

  describe "set_variable/3" do
    setup do
      {:ok, luau: Luau.init()}
    end

    test "sets a variable", %{luau: luau} do
      name = ["name"]
      value = "Robert"
      assert {:ok, %Luau{variables: %{^name => ^value}}} = Luau.set_variable(luau, name, value)
    end

    test "wraps variable path as necessary", %{luau: luau} do
      name = "name"
      value = "Robert"
      assert {:ok, %Luau{variables: %{[^name] => ^value}}} = Luau.set_variable(luau, name, value)
    end
  end

  describe "load_module!/2" do
    setup do
      {:ok, luau: Luau.init()}
    end

    test "load a Luau.Library to the lua luau", %{luau: luau} do
      assert %Luau{modules: [EvenLibrary, AdderLibrary]} =
               loaded_luau = luau |> Luau.load_module!(AdderLibrary) |> Luau.load_module!(EvenLibrary)

      script = """
      local a = Adder.add(3,3)
      local b = Even.is_even(a)
      return b
      """

      assert {:ok, [true], _luau} = Luau.run(loaded_luau, script)
    end
  end

  describe "load_lua!/2" do
    setup do
      {:ok, luau: Luau.init()}
    end

    test "raises an error for missing files", %{luau: luau} do
      assert_raise RuntimeError, fn ->
        Luau.load_lua!(luau, "missing.lua")
      end
    end

    test "loads simple lua script into luau", %{luau: luau} do
      path = Path.join([__DIR__, "support", "hello.lua"])
      assert %Luau{lua_files: [^path]} = loaded_luau = Luau.load_lua!(luau, path)

      script = """
      return hello("Robert")
      """

      assert {:ok, ["Hello Robert!"], _luau} = Luau.run(loaded_luau, script)
    end

    test "loads lua module into luau", %{luau: luau} do
      path = Path.join([__DIR__, "support", "enum.lua"])

      assert {:ok, %Luau{lua_files: [^path]} = loaded_luau} =
               luau
               |> Luau.load_lua!(path)
               |> Luau.set_variable("numbers", [1, 2, 3, 4])

      script = """
      local all = Enum.all(numbers, function(n) return n % 2 == 0 end) 
      local any = Enum.any(numbers, function(n) return n % 2 == 0 end)

      return all, any
      """

      assert {:ok, [false, true], _luau} = Luau.run(loaded_luau, script)
    end
  end
end
