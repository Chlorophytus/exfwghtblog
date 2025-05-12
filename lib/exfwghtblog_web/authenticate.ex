defmodule ExfwghtblogWeb.Authenticate do
  import Plug.Conn

  # How many seconds should we keep the user logged in?
  @get_ttl 10 * 60

  def init(_args), do: {}

  def call(conn, _args) do
    token = conn |> get_session(:exfwghtblog_token)

    case Phoenix.Token.verify(ExfwghtblogWeb.Endpoint, "access", token, max_age: @get_ttl) do
      {:ok, user_id} -> conn |> assign(:user_or_error, user_id)
      {:error, error} -> conn |> assign(:user_or_error, error)
    end
  end
end
