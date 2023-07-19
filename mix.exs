defmodule Exfwghtblog.MixProject do
  use Mix.Project

  def project do
    [
      app: :exfwghtblog,
      version: "0.6.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Exfwghtblog.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # HTTP API framework
      {:plug_cowboy, "~> 2.6"},

      # JSON framework for HTTP API
      {:jason, "~> 1.4"},

      # Database storage API basis
      {:ecto, "~> 3.10"},

      # PostgreSQL database adapter
      {:ecto_sql, "~> 3.10"},

      # PostgreSQL database client
      {:postgrex, "~> 0.17.2"},

      # Code well-formedness enhancement
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}

      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
