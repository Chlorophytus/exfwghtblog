defmodule ExfwghtblogWeb.AuthController do
  @moduledoc """
  Controller for logging in users
  """
  import Ecto.Query
  use ExfwghtblogWeb, :controller

  # How many minutes should we keep the user logged in?
  @time_to_live 5

  @doc """
  Logs in a user using the Guardian module
  """
  def login(conn, %{"username" => name, "password" => pass}) do
    user =
      Exfwghtblog.Repo.one(
        from u in Exfwghtblog.User, where: ilike(u.username, ^name), select: u
      )

    if Argon2.verify_pass(pass, user.pass_hash) do
      conn
      |> fetch_session()
      |> Exfwghtblog.Guardian.Plug.sign_in(user, %{typ: "access"},
        ttl: {@time_to_live, :minute}
      )
      |> send_resp(200, "OK")
    else
      Argon2.no_user_verify()
      conn |> send_resp(401, "Unauthorized")
    end
  end

  @doc """
  Logs out the current user, revoking the token
  """
  def logout(conn, _params) do
    conn
    |> fetch_session()
    |> Exfwghtblog.Guardian.Plug.sign_out()
    |> send_resp(200, "OK")
  end

  @behaviour Guardian.Plug.ErrorHandler
  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    conn |> send_resp(500, "Internal Server Error")
  end
end
