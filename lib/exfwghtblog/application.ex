defmodule Exfwghtblog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :persistent_term.put(
      Exfwghtblog.Version,
      case Application.get_env(:exfwghtblog, :commit_sha_result) do
        {sha, 0} ->
          "#{Application.spec(:exfwghtblog, :vsn)}-#{sha |> String.replace_trailing("\n", "")}"

        _ ->
          Application.spec(:exfwghtblog, :vsn)
      end
    )

    children = [
      # Start the Telemetry supervisor
      ExfwghtblogWeb.Telemetry,
      # Start the Ecto repository
      Exfwghtblog.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exfwghtblog.PubSub},
      # Start Finch
      {Finch, name: Exfwghtblog.Finch},
      # Start the Endpoint (http/https)
      ExfwghtblogWeb.Endpoint,
      # Start a worker by calling: Exfwghtblog.Worker.start_link(arg)
      # {Exfwghtblog.Worker, arg}

      Exfwghtblog.BatchSupervisor,
      Exfwghtblog.RssSupervisor,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exfwghtblog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExfwghtblogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
