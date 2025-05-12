defmodule ExfwghtblogWeb.Authenticate do
  import Plug.Conn

  # How many seconds should we keep the user logged in?
  @get_ttl 10 * 60

  def init(_args), do: {}

  def call(%Plug.Conn{params: %{"token" => token}} = conn, _args) do
    case Phoenix.Token.verify(ExfwghtblogWeb.Endpoint, "access", token, max_age: @get_ttl) do
      {:ok, user_id} -> conn |> assign(:user_or_error, user_id)
      {:error, error} -> conn |> assign(:user_or_error, error)
    end
  end

  def call(conn, _args) do
    conn
  end
end
