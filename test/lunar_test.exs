defmodule LunarTest do
  use ExUnit.Case

  setup do
    {:ok, lunar: Lunar.init()}
  end

  describe ":telemetry" do
    setup do
      _ref =
        :telemetry_test.attach_event_handlers(self(), [
          [:lunar, :init],
          [:lunar, :clone],
          [:lunar, :deflua, :invocation],
          [:lunar, :load_lua!],
          [:lunar, :load_module!],
          [:lunar, :run, :failure],
          [:lunar, :run, :success],
          [:lunar, :run],
          [:lunar, :set_variable]
        ])

      :ok
    end

    test "emits [:lunar, :init]" do
      Lunar.init()
      assert_receive {[:lunar, :init], _ref, %{count: 1}, %{}}
    end

    test "emits [:lunar, :clone]", %{lunar: lunar} do
      Lunar.clone(lunar)
      assert_receive {[:lunar, :clone], _ref, %{count: 1}, %{}}
    end

    test "emits [:lunar, :set_variable]", %{lunar: lunar} do
      Lunar.set_variable(lunar, :foo, "bar")
      assert_receive {[:lunar, :set_variable], _ref, %{count: 1}, %{key: [:foo], value: "bar"}}
    end

    test "emits [:lunar, :load_module!]", %{lunar: lunar} do
      Lunar.load_module!(lunar, Math)
      assert_receive {[:lunar, :load_module!], _ref, %{count: 1}, %{scope: "Math", module_name: Math}}
    end

    test "emits [:lunar, :load_lua!]", %{lunar: lunar} do
      path = Path.join([__DIR__, "support", "hello.lua"])
      Lunar.load_lua!(lunar, path)
      assert_receive {[:lunar, :load_lua!], _ref, %{count: 1}, %{path: ^path}}
    end

    test "emits [:lunar, :run, :success]", %{lunar: lunar} do
      Lunar.run(lunar, "return true")
      assert_receive {[:lunar, :run, :success], _ref, %{count: 1}, %{}}
    end

    test "emits [:lunar, :run, :failure]", %{lunar: lunar} do
      # Results in a syntax error
      Lunar.run(lunar, "1+1=2")

      assert_receive {[:lunar, :run, :failure], _ref, %{count: 1},
                      %{reason: "line 1: luerl_parse syntax error before: 1"}}
    end

    test "emits [:lunar, :deflua, :invocation]", %{lunar: lunar} do
      script = """
      return Math.sub(2, 1)
      """

      lunar
      |> Lunar.load_module!(Math)
      |> Lunar.run(script)

      assert_receive {[:lunar, :deflua, :invocation], _ref, %{count: 1},
                      %{args: [2, 1], function_name: :sub, scope: "Math", module_name: Math}}
    end
  end

  describe "clone/1" do
    test "sets a new `id`", %{lunar: lunar} do
      assert lunar.id != Lunar.clone(lunar).id
    end
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

  describe "get_variable/2" do
    test "get a variable", %{lunar: lunar} do
      name = "name"
      value = "Robert"

      {:ok, lunar} = Lunar.set_variable(lunar, name, value)
      assert {:ok, ^value} = Lunar.get_variable(lunar, name)
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

    test "evaluates lua script and allow state changes to be accessed", %{lunar: lunar} do
      {:ok, updated_lunar} = Lunar.set_variable(lunar, "name", "Robert")
      assert {:ok, "Robert"} = Lunar.get_variable(updated_lunar, "name")

      {:ok, _result, final_lunar} = Lunar.run(updated_lunar, "name = \"Steve\"")
      assert {:ok, "Steve"} = Lunar.get_variable(final_lunar, "name")
    end
  end
end
