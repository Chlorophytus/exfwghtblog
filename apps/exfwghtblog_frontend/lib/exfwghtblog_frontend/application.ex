defmodule ExfwghtblogFrontend.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Finch, name: ExfwghtblogFrontend.Finch},
      {Phoenix.PubSub, name: ExfwghtblogFrontend.PubSub},
      # Start the Telemetry supervisor
      ExfwghtblogFrontend.Telemetry,
      # Start the Endpoint (http/https)
      ExfwghtblogFrontend.Endpoint
      # Start a worker by calling: ExfwghtblogFrontend.Worker.start_link(arg)
      # {ExfwghtblogFrontend.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExfwghtblogFrontend.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExfwghtblogFrontend.Endpoint.config_change(changed, removed)
    :ok
  end
end
