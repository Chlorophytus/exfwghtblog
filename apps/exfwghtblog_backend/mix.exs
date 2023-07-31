defmodule ExfwghtblogBackend.MixProject do
  use Mix.Project

  def project do
    [
      app: :exfwghtblog_backend,
      version: "0.6.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ExfwghtblogBackend.Application, []},
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

      # Authentication cookies
      {:guardian, "~> 2.3"},

      # Authentication passwords
      {:argon2_elixir, "~> 3.1"},

      # Log the remote IP address if we're using a reverse proxy
      {:remote_ip, "~> 1.1"},

      # Code well-formedness enhancements
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.drop --quiet", "ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
