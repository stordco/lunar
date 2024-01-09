defmodule Luau do
  @moduledoc """
  Let's get this party started!
  """
  @type t :: %__MODULE__{
          id: nil | String.t(),
          lua_files: [String.t()],
          modules: [Luau.Library.t()],
          state: tuple(),
          variables: %{[String.t()] => any()}
        }

  alias Luerl.New, as: Luerl

  defstruct id: nil, modules: [], lua_files: [], state: nil, variables: %{}

  @type result :: {:ok, t()}
  @type error :: {:error, atom() | String.t()}

  @doc """
  Initialize a new Luau
  """
  @spec init() :: Luau.t()
  def init do
    %Luau{id: Nanoid.generate(), state: Luerl.init()}
  end

  @doc """
  Encodes an Elixir value and makes it available at the key/path.

  # Examples

    iex> luau = Luau.init()
    iex> luau = Luau.set_variable(luau, "a", 1)
  """
  @spec set_variable(Luau.t(), [String.t()] | String.t(), any()) :: result | error
  def set_variable(luau, key, value) do
    key = List.wrap(key)

    case Luerl.set_table_keys_dec(luau.state, key, value) do
      {:ok, _result, new_state} ->
        {:ok, %{luau | state: new_state, variables: Map.put(luau.variables, key, value)}}

      {:lua_error, reason, _state} ->
        {:error, reason}
    end
  end

  @doc """
  Load a Luau.Library into state.

  # Examples

    iex> luau = Luau.init()
    iex> luau = Luau.load_module!(luau, Math)
  """
  @spec load_module!(Luau.t(), Luau.Library.t()) :: Luau.t()
  def load_module!(luau, module) do
    new_state = Luerl.load_module_dec(luau.state, [module.scope()], module)
    %{luau | state: new_state, modules: [module | luau.modules]}
  end

  @doc """
  Load Lua code into state from file.
  """
  @spec load_lua!(Luau.t(), String.t()) :: Luau.t()
  def load_lua!(luau, path) do
    case Luerl.dofile(luau.state, String.to_charlist(path)) do
      {:ok, _result, new_state} ->
        %{luau | state: new_state, lua_files: [path | luau.lua_files]}

      :error ->
        raise "Could not load Lua file #{path}, file not found"
    end
  end

  @doc """
  Evaluate Lua code within a given Luau
    
  # Examples

    iex> luau = Luau.init()
    iex> luau = Luau.load_module!(luau, Math)
    iex> {:ok, luau} = Luau.set_variable(luau, a, 1)
    iex> {:ok, [10], _luau} = Luau.run(luau, "return Math.add(a, 9)")
  """
  @spec run(Luau.t(), String.t()) :: {:ok, any(), Luau.t()} | error
  def run(luau, lua) do
    case Luerl.do(luau.state, lua) do
      {:ok, result, new_state} ->
        {:ok, result, %{luau | state: new_state}}

      {:error, reason, _state} ->
        {:error, reason}
    end
  end
end
