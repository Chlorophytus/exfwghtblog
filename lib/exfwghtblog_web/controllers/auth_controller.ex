defmodule ExfwghtblogWeb.AuthController do
  @moduledoc """
  Controller for logging in users
  """
  import Ecto.Query
  import ExfwghtblogWeb.Gettext
  use ExfwghtblogWeb, :controller

  # How many minutes should we keep the user logged in?
  @time_to_live 10

  @doc """
  Logs in a user using the Guardian module
  """
  def login(conn, %{"username" => name, "password" => pass}) do
    user =
      Exfwghtblog.Repo.one(from u in Exfwghtblog.User, where: ilike(u.username, ^name), select: u)

    if Argon2.verify_pass(pass, user.pass_hash) do
      conn =
        conn
        |> Exfwghtblog.Guardian.Plug.sign_in(user, %{typ: "access"}, ttl: {@time_to_live, :minute})

      conn
      |> fetch_session()
      |> put_resp_content_type("application/json")
      |> send_resp(
        200,
        Jason.encode!(%{
          ok: true,
          ttl: @time_to_live,
          token: Exfwghtblog.Guardian.Plug.current_token(conn)
        })
      )
    else
      Argon2.no_user_verify()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(401, Jason.encode!(%{ok: false, info: gettext("Authentication failed")}))
    end
  end

  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, info, _opts) do
    case info do
      {:invalid_token, :token_expired} ->
        conn
        |> fetch_session()
        |> Exfwghtblog.Guardian.Plug.sign_out()
        |> fetch_flash()
        |> put_flash(:error, gettext("You were signed out due to inactivity"))
        |> redirect(to: "/")

      _other ->
        conn
        |> fetch_session()
        |> Exfwghtblog.Guardian.Plug.sign_out()
        |> fetch_flash()
        |> put_flash(:error, gettext("Authentication failed due to a server error"))
        |> redirect(to: "/")
    end
  end
end
