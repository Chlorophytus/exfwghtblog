defmodule Exfwghtblog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Exfwghtblog.Worker.start_link(arg)
      # {Exfwghtblog.Worker, arg}
      {Plug.Cowboy, scheme: :http, plug: Exfwghtblog.Router, port: 80},

      Exfwghtblog.AwsAgent
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exfwghtblog.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
