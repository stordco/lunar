defmodule Luau.Runtime do
  @type t :: %__MODULE__{
          id: nil | String.t(),
          lua: [String.t()],
          modules: [Luau.Library.t()],
          state: tuple(),
          variables: %{[String.t()] => any()}
        }

  alias Luerl.New, as: Luerl

  defstruct id: nil, modules: [], lua: [], state: nil, variables: %{}

  @type result :: {:ok, t()}
  @type error :: {:error, atom() | String.t()}

  @spec init() :: Luau.Runtime.t()
  def init do
    %Luau.Runtime{id: Nanoid.generate(), state: Luerl.init()}
  end

  @spec set_variable(Luau.Runtime.t(), [String.t()] | String.t(), any()) :: result | error
  def set_variable(runtime, key, value) do
    key = List.wrap(key)

    case Luerl.set_table_keys_dec(runtime.state, key, value) do
      {:ok, _result, new_state} ->
        {:ok, %{runtime | state: new_state, variables: Map.put(runtime.variables, key, value)}}

      {:lua_error, reason, _state} ->
        {:error, reason}
    end
  end

  @spec load_module!(Luau.Runtime.t(), Luau.Library.t()) :: Luau.Runtime.t()
  def load_module!(runtime, module) do
    new_state = Luerl.load_module_dec(runtime.state, [module.scope()], module)
    %{runtime | state: new_state, modules: [module | runtime.modules]}
  end

  @spec load_lua!(Luau.Runtime.t(), String.t()) :: Luau.Runtime.t()
  def load_lua!(runtime, path) do
    case Luerl.dofile(runtime.state, String.to_charlist(path)) do
      {:ok, _result, new_state} ->
        %{runtime | state: new_state, lua: [path | runtime.lua]}

      :error ->
        raise "Could not load Lua file #{path}, file not found"
    end
  end

  @spec run(Luau.Runtime.t(), String.t()) :: {:ok, any(), Luau.Runtime.t()} | error
  def run(runtime, lua) do
    case Luerl.do(runtime.state, lua) do
      {:ok, result, new_state} ->
        {:ok, result, %{runtime | state: new_state}}

      {:error, reason, _state} ->
        {:error, reason}
    end
  end
end
