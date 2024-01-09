defmodule Luau do
  @moduledoc """
  Let's get this party started!
  """

  alias Luau.Runtime

  @spec init() :: Runtime.t()
  def init do
    Runtime.init()
  end

  def run(runtime, lua) do
    Runtime.run(runtime, lua)
  end
end
