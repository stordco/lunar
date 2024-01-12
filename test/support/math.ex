defmodule Math do
  use Lunar.Library, scope: "Math"

  deflua add(a, b) do
    a + b
  end

  deflua sub(a, b) do
    a - b
  end
end
