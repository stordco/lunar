defmodule Lunar.MixProject do
  use Mix.Project

  def project do
    [
      app: :lunar,
      deps: deps(),
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: "0.1.0"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "priv/scripts"]
  defp elixirc_paths(:dev), do: ["lib", "priv/scripts"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:luerl, "~> 1.1"},
      {:nanoid, "~> 2.1.0"},

      # Dev & Test dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:dev, :test], runtime: false}
    ]
  end
end
