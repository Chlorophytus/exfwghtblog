defmodule Exfwghtblog.MixProject do
  use Mix.Project

  def project do
    [
      app: :exfwghtblog,
      version: "0.3.1",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Exfwghtblog.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 2.5"},
      {:earmark, "~> 1.4"},
      {:aws, "~> 0.9"},
      {:hackney, "~> 1.17"},
      {:calendar, "~> 1.0"}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
