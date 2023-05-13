defmodule ExfwghtblogWeb.AuthController do
  @moduledoc """
  Controller for logging in users
  """
  import ExfwghtblogWeb.Gettext
  use ExfwghtblogWeb, :controller

  # How many minutes should we keep the user logged in?
  @time_to_live 10

  @doc """
  Logs in a user using the Guardian module
  """
  def login(conn, %{"username" => username, "password" => password}) do
    batch_id = Exfwghtblog.BatchProcessor.check_password(username, password)

    receive do
      {:batch_done, id, batch_result} when id == batch_id ->
        case batch_result do
          %{status: :ok, user: user} ->
            conn =
              conn
              |> Exfwghtblog.Guardian.Plug.sign_in(user, %{typ: "access"},
                ttl: {@time_to_live, :minute}
              )

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

          %{status: :invalid_password, user: _user} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{ok: false, info: gettext("Authentication failed")}))

          %{status: :does_not_exist, user: _user} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(500, Jason.encode!(%{ok: false, info: gettext("User does not exist")}))
        end
    after 3000 ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{ok: false, info: gettext("Internal server error")}))
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
        |> put_flash(:error, gettext("You were logged out due to inactivity"))
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
