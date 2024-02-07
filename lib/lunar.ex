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
  Initialize a new Lunar runtime
  """
  @spec init() :: Lunar.t()
  def init do
    :telemetry.execute([:lunar, :init], %{count: 1}, %{})
    %Lunar{id: Nanoid.generate(), state: Luerl.init()}
  end

  @doc """
  A convenience function for copying a Lunar runtime and setting a new `id`
  """
  def clone(lunar) do
    new_id = Nanoid.generate()

    :telemetry.execute([:lunar, :clone], %{count: 1}, %{})

    %{lunar | id: new_id}
  end

  @spec get_variable(Lunar.t(), [String.t()] | String.t()) :: result | error
  def get_variable(lunar, key) do
    key = List.wrap(key)

    case Luerl.get_table_keys_dec(lunar.state, key) do
      {:ok, value, _new_state} ->
        :telemetry.execute([:lunar, :get_variable], %{count: 1}, %{key: key, value: value})

        {:ok, value}

      {:lua_error, reason, _state} ->
        {:error, reason}
    end
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
        :telemetry.execute([:lunar, :set_variable], %{count: 1}, %{
          key: key,
          value: value
        })

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
    :telemetry.execute([:lunar, :load_module!], %{count: 1}, %{
      scope: module.scope(),
      module_name: module
    })

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
        :telemetry.execute([:lunar, :load_lua!], %{count: 1}, %{path: path})

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
    :telemetry.span(
      [:lunar, :run],
      %{},
      fn ->
        result = run_lunar(lunar, lua)
        {result, %{}}
      end
    )
  end

  defp run_lunar(lunar, lua) do
    case Luerl.do(lunar.state, lua) do
      {:ok, result, new_state} ->
        :telemetry.execute([:lunar, :run, :success], %{count: 1}, %{})

        {:ok, result, %{lunar | state: new_state}}

      {:error, reason, _state} ->
        :telemetry.execute([:lunar, :run, :failure], %{count: 1}, %{
          reason: parse_luerl_error(reason)
        })

        {:error, reason}
    end
  end

  defp parse_luerl_error([{line_no, type, reason}]), do: "line #{line_no}: #{type} #{reason}"
end
