defmodule LuauTest do
  use ExUnit.Case

  setup do
    {:ok, luau: Luau.init()}
  end

  describe "set_variable/3" do
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
    test "load a Luau.Library to the luau", %{luau: luau} do
      assert %Luau{modules: [Math]} = Luau.load_module!(luau, Math)
    end
  end

  describe "load_lua!/2" do
    test "raises an error for missing files", %{luau: luau} do
      assert_raise RuntimeError, fn ->
        Luau.load_lua!(luau, "missing.lua")
      end
    end

    test "loads simple lua script into luau", %{luau: luau} do
      path = Path.join([__DIR__, "support", "hello.lua"])
      assert %Luau{lua_files: [^path]} = Luau.load_lua!(luau, path)
    end
  end

  describe "run/2" do
    test "evaluates lua script and returns the result", %{luau: luau} do
      path = Path.join([__DIR__, "support", "hello.lua"])

      assert {:ok, ["Hello Robert!"], _luau} =
               luau
               |> Luau.load_lua!(path)
               |> Luau.run("return hello('Robert')")
    end

    test "supports multiple return values", %{luau: luau} do
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

    test "supports running with state modified by another run", %{luau: luau} do
      {:ok, luau} =
        luau
        |> Luau.load_module!(Math)
        |> Luau.set_variable("numbers", [1, 2, 3])

      # We don't use `local` within these tests intentionally
      {:ok, _, luau} = Luau.run(luau, "size = #numbers")

      script = """
      double_size = Math.add(size, size)
      return double_size
      """

      {:ok, [6], luau} = Luau.run(luau, script)

      {:ok, [5], _luau} = Luau.run(luau, "return Math.sub(double_size, 1)")
    end
  end
end
