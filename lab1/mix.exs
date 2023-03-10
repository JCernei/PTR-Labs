defmodule Lab1.MixProject do
  use Mix.Project

  def project do
    [
      app: :lab1,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      # applications: [:httpoison, :hackney],
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 2.0"},
      {:floki, "~> 0.34.2"},
      {:jason, "~> 1.4"}
      # {:hackney, "~> 1.18"}
      # {:public_key, "~> 1.12.1"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
