defmodule Lunar.MixProject do
  use Mix.Project

  def project do
    [
      app: :lunar,
      name: "Lunar",
      deps: deps(),
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      version: "1.0.1",
      test_coverage: [tool: ExCoveralls],
      package: package()
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
      {:telemetry, ">= 1.0.0"},

      # Dev & Test dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.28", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.17.1", only: :test}
    ]
  end

  defp package do
    [
      files: ~w(lib mix.exs .formatter.exs README.md CHANGELOG.md),
      licenses: ["Apache-2.0"],
      links: %{
        Changelog: "https://github.com/stordco/lunar/releases",
        GitHub: "https://github.com/stordco/lunar"
      }
    ]
  end
end
