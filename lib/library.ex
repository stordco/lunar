defmodule Luau.Library do
  @moduledoc """
    Defines a library that will extend the Lua runtime.

    ## Example usage

      defmodule MyLibrary do
        use Luau.Library, scope: "my_library"

        deflua hello(name) do
          "Hello, \#{name}!"
        end
      end
    
    In our Lua code, we can now call `my_library.hello("Robert")` and get back `"Hello, Robert!"`.
  """
  @type t :: __MODULE__

  @callback install(tuple()) :: tuple()
  @callback table() :: [tuple()]
  @callback scope() :: String.t()

  defmacro __using__(opts) do
    scope = Keyword.fetch!(opts, :scope)

    quote do
      require Record
      Record.defrecord(:erl_mfa, Record.extract(:erl_mfa, from_lib: "luerl/include/luerl.hrl"))

      Module.register_attribute(__MODULE__, :lua_functions, accumulate: true, persist: true)

      import Luau.Library, only: [deflua: 2]

      @before_compile unquote(__MODULE__)

      @behaviour Luau.Library

      @impl Luau.Library
      def install(luerl_state) do
        :luerl_heap.alloc_table(table(), luerl_state)
      end

      @impl Luau.Library
      def scope, do: unquote(scope)
    end
  end

  defmacro __before_compile__(_) do
    quote do
      @impl Luau.Library
      def table do
        functions =
          :functions
          |> __MODULE__.__info__()
          |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))

        Enum.flat_map(@lua_functions, fn {func, wrapped_func} ->
          functions
          |> Map.get(func, [])
          |> Enum.map(&{to_string(func), erl_mfa(m: __MODULE__, f: wrapped_func, a: &1)})
        end)
      end
    end
  end

  defmacro deflua(call, do: body) do
    {func, _line, _args} = call

    # credo:disable-for-next-line
    wrapped_func = String.to_atom("lua_wrapped_#{func}")

    quote do
      @lua_functions {unquote(func), unquote(wrapped_func)}
      def unquote(call) do
        unquote(body)
      end

      def unquote(wrapped_func)(_arity, args, state) do
        res = apply(__MODULE__, unquote(func), args)
        {:ok, state}
      end
    end
  end
end
