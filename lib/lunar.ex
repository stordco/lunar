defmodule Lunar do
  @moduledoc """
  Let's get this party started!
  """
  @type t :: %__MODULE__{
          id: nil | String.t(),
          lua_files: [String.t()],
          modules: [Lunar.Library.t()],
          state: tuple(),
          variables: %{[String.t()] => any()}
        }

  alias Luerl.New, as: Luerl

  defstruct id: nil, modules: [], lua_files: [], state: nil, variables: %{}

  @type result :: {:ok, t()}
  @type error :: {:error, atom() | String.t()}

  @doc """
  Initialize a new Lunar
  """
  @spec init() :: Lunar.t()
  def init do
    %Lunar{id: Nanoid.generate(), state: Luerl.init()}
  end

  @doc """
  Encodes an Elixir value and makes it available at the key/path.

  # Examples

    iex> lunar = Lunar.init()
    iex> lunar = Lunar.set_variable(lunar, "a", 1)
  """
  @spec set_variable(Lunar.t(), [String.t()] | String.t(), any()) :: result | error
  def set_variable(lunar, key, value) do
    key = List.wrap(key)

    case Luerl.set_table_keys_dec(lunar.state, key, value) do
      {:ok, _result, new_state} ->
        {:ok, %{lunar | state: new_state, variables: Map.put(lunar.variables, key, value)}}

      {:lua_error, reason, _state} ->
        {:error, reason}
    end
  end

  @doc """
  Load a Lunar.Library into state.

  # Examples

    iex> lunar = Lunar.init()
    iex> lunar = Lunar.load_module!(lunar, Math)
  """
  @spec load_module!(Lunar.t(), Lunar.Library.t()) :: Lunar.t()
  def load_module!(lunar, module) do
    new_state = Luerl.load_module_dec(lunar.state, [module.scope()], module)
    %{lunar | state: new_state, modules: [module | lunar.modules]}
  end

  @doc """
  Load Lua code into state from file.
  """
  @spec load_lua!(Lunar.t(), String.t()) :: Lunar.t()
  def load_lua!(lunar, path) do
    case Luerl.dofile(lunar.state, String.to_charlist(path)) do
      {:ok, _result, new_state} ->
        %{lunar | state: new_state, lua_files: [path | lunar.lua_files]}

      :error ->
        raise "Could not load Lua file #{path}, file not found"
    end
  end

  @doc """
  Evaluate Lua code within a given Lunar

  # Examples

    iex> lunar = Lunar.init()
    iex> lunar = Lunar.load_module!(lunar, Math)
    iex> {:ok, lunar} = Lunar.set_variable(lunar, a, 1)
    iex> {:ok, [10], _lunar} = Lunar.run(lunar, "return Math.add(a, 9)")
  """
  @spec run(Lunar.t(), String.t()) :: {:ok, any(), Lunar.t()} | error
  def run(lunar, lua) do
    case Luerl.do(lunar.state, lua) do
      {:ok, result, new_state} ->
        {:ok, result, %{lunar | state: new_state}}

      {:error, reason, _state} ->
        {:error, reason}
    end
  end
end
