defmodule Luau do
  @moduledoc """
  Let's get this party started!
  """

  alias Luau.Runtime

  @spec initialize(Keyword.t()) :: Runtime.t()
  def initialize(args) do
    Runtime.initialize(args)
  end

  @spec execute(Runtime.t(), String.t()) :: {any(), Runtime.t()}
  def execute(runtime, lua) do
    {res, new_state} = :luerl.do(lua, runtime.state)

    {res, %{runtime | state: new_state}}
  end
end
