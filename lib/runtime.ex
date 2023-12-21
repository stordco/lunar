defmodule Luau.Runtime do
  @type t :: %__MODULE__{
          id: nil | String.t(),
          libraries: [Luau.Library.t()],
          state: tuple(),
          variables: %{String.t() => any()}
        }

  defstruct id: nil, libraries: [], state: nil, variables: %{}

  @spec initialize(Keyword.t()) :: Luau.Runtime.t()
  def initialize(opts \\ []) do
    libraries = Keyword.get(opts, :libraries, [])
    variables = Keyword.get(opts, :variables, %{})
    runtime = %Luau.Runtime{id: Nanoid.generate(), state: :luerl.init()}

    runtime
    |> add_libraries(libraries)
    |> set_variables(variables)
  end

  @spec set_variable(Luau.Runtime.t(), String.t(), any()) :: Luau.Runtime.t()
  def set_variable(runtime, key, value) do
    new_state = :luerl.set_table([key], value, runtime.state)

    %{runtime | state: new_state, variables: Map.put(runtime.variables, key, value)}
  end

  @spec add_library(Luau.Runtime.t(), Luau.Library.t()) :: Luau.Runtime.t()
  def add_library(runtime, library) do
    new_state = :luerl.load_module([library.scope()], library, runtime.state)

    %{runtime | state: new_state, libraries: [library | runtime.libraries]}
  end

  @spec run(Luau.Runtime.t(), String.t()) :: {any(), Luau.Runtime.t()}
  def run(runtime, lua) do
    {res, new_state} = :luerl.do(lua, runtime.state)

    {res, %{runtime | state: new_state}}
  end

  defp add_libraries(runtime, libraries) do
    Enum.reduce(libraries, runtime, &add_library(&2, &1))
  end

  defp set_variables(runtime, variables) do
    Enum.reduce(variables, runtime, fn {key, value}, runtime -> set_variable(runtime, key, value) end)
  end
end
