defmodule Exfwghtblog.Application do
  @moduledoc """
  `exfwghtblog` application
  """
  use Application

  @impl true
  def start(_type, _args) do
    # Put in a `persistent_term` with the application version info.
    :persistent_term.put(
      Exfwghtblog.Version,
      case Application.get_env(:exfwghtblog, :commit_sha_result) do
        {sha, 0} ->
          "#{Application.spec(:exfwghtblog, :vsn)}-git+#{sha |> String.replace_trailing("\n", "")}"

        _ ->
          Application.spec(:exfwghtblog, :vsn)
      end
    )

    # Start the application's children
    children = [
      # `repo.ex`
      Exfwghtblog.Repo,

      # `api.ex`
      {Plug.Cowboy,
       scheme: :http, plug: Exfwghtblog.API, options: [ip: {127, 0, 0, 1}, port: 8080]}
    ]

    opts = [strategy: :one_for_one, name: Exfwghtblog.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
