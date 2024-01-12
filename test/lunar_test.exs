defmodule LunarTest do
  use ExUnit.Case

  setup do
    {:ok, lunar: Lunar.init()}
  end

  describe "set_variable/3" do
    test "sets a variable", %{lunar: lunar} do
      name = ["name"]
      value = "Robert"
      assert {:ok, %Lunar{variables: %{^name => ^value}}} = Lunar.set_variable(lunar, name, value)
    end

    test "wraps variable path as necessary", %{lunar: lunar} do
      name = "name"
      value = "Robert"
      assert {:ok, %Lunar{variables: %{[^name] => ^value}}} = Lunar.set_variable(lunar, name, value)
    end
  end

  describe "load_module!/2" do
    test "load a Lunar.Library to the lunar", %{lunar: lunar} do
      assert %Lunar{modules: [Math]} = Lunar.load_module!(lunar, Math)
    end
  end

  describe "load_lua!/2" do
    test "raises an error for missing files", %{lunar: lunar} do
      assert_raise RuntimeError, fn ->
        Lunar.load_lua!(lunar, "missing.lua")
      end
    end

    test "loads simple lua script into lunar", %{lunar: lunar} do
      path = Path.join([__DIR__, "support", "hello.lua"])
      assert %Lunar{lua_files: [^path]} = Lunar.load_lua!(lunar, path)
    end
  end

  describe "run/2" do
    test "evaluates lua script and returns the result", %{lunar: lunar} do
      path = Path.join([__DIR__, "support", "hello.lua"])

      assert {:ok, ["Hello Robert!"], _lunar} =
               lunar
               |> Lunar.load_lua!(path)
               |> Lunar.run("return hello('Robert')")
    end

    test "supports multiple return values", %{lunar: lunar} do
      path = Path.join([__DIR__, "support", "enum.lua"])

      assert {:ok, %Lunar{lua_files: [^path]} = loaded_lunar} =
               lunar
               |> Lunar.load_lua!(path)
               |> Lunar.set_variable("numbers", [1, 2, 3, 4])

      script = """
      local all = Enum.all(numbers, function(n) return n % 2 == 0 end)
      local any = Enum.any(numbers, function(n) return n % 2 == 0 end)

      return all, any
      """

      assert {:ok, [false, true], _lunar} = Lunar.run(loaded_lunar, script)
    end

    test "supports running with state modified by another run", %{lunar: lunar} do
      {:ok, lunar} =
        lunar
        |> Lunar.load_module!(Math)
        |> Lunar.set_variable("numbers", [1, 2, 3])

      # We don't use `local` within these tests intentionally
      {:ok, _, lunar} = Lunar.run(lunar, "size = #numbers")

      script = """
      double_size = Math.add(size, size)
      return double_size
      """

      {:ok, [6], lunar} = Lunar.run(lunar, script)

      {:ok, [5], _lunar} = Lunar.run(lunar, "return Math.sub(double_size, 1)")
    end
  end
end
