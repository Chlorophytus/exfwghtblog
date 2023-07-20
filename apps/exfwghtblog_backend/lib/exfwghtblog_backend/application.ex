defmodule ExfwghtblogBackend.Application do
  @moduledoc """
  `exfwghtblog_backend` application
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Put in a `persistent_term` with the application version info.
    :persistent_term.put(
      ExfwghtblogBackend.Version,
      case Application.get_env(:exfwghtblog_backend, :commit_sha_result) do
        {sha, 0} ->
          "#{Application.spec(:exfwghtblog_backend, :vsn)}-git+#{sha |> String.replace_trailing("\n", "")}"

        _ ->
          Application.spec(:exfwghtblog_backend, :vsn)
      end
    )

    # Start the application's children
    children = [
      # `repo.ex`
      ExfwghtblogBackend.Repo,

      # `api.ex`
      {Plug.Cowboy,
       scheme: :http, plug: ExfwghtblogBackend.API, options: [ip: {127, 0, 0, 1}, port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: ExfwghtblogBackend.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
