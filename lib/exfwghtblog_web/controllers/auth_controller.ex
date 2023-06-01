defmodule ExfwghtblogWeb.AuthController do
  @moduledoc """
  Controller for logging in users
  """
  import ExfwghtblogWeb.Gettext
  use ExfwghtblogWeb, :controller

  # How many minutes should we keep the user logged in?
  def get_ttl_minutes(), do: 10

  defp map_error(:does_not_exist), do: 500
  defp map_error(:invalid_password), do: 401
  defp map_error(:rate_limited), do: 429

  @doc """
  Logs in a user using the Guardian module
  """
  def login(conn, %{"username" => username, "password" => password}) do
    origin_hash = Exfwghtblog.Batch.origin_hash(conn.remote_ip)
    batch_id = Exfwghtblog.Batch.check_password(username, password, origin_hash)

    receive do
      {:batch_done, id, rate_limit_info, batch_result} when id == batch_id ->
        case batch_result.status do
          :ok ->
            conn =
              conn
              |> Exfwghtblog.Guardian.Plug.sign_in(batch_result.user, %{typ: "access"},
                ttl: {get_ttl_minutes(), :minute}
              )

            conn
            |> merge_resp_headers([
              {"x-ratelimit-bucket", origin_hash},
              {"x-ratelimit-limit", get_in(rate_limit_info, [:limit]) |> to_string()},
              {"x-ratelimit-remaining", get_in(rate_limit_info, [:remaining]) |> to_string()},
              {"x-ratelimit-reset", get_in(rate_limit_info, [:reset]) |> to_string()}
            ])
            |> put_view(json: ExfwghtblogWeb.AuthJSON)
            |> render(:login_success, token: Exfwghtblog.Guardian.Plug.current_token(conn))

          error ->
            code = map_error(error)

            conn
            |> merge_resp_headers([
              {"x-ratelimit-bucket", origin_hash},
              {"x-ratelimit-limit",
               get_in(batch_result, [:rate_limit_info, :limit]) |> to_string()},
              {"x-ratelimit-remaining",
               get_in(batch_result, [:rate_limit_info, :remaining]) |> to_string()},
              {"x-ratelimit-reset",
               get_in(batch_result, [:rate_limit_info, :reset]) |> to_string()}
            ])
            |> put_view(json: ExfwghtblogWeb.ErrorJSON)
            |> put_status(code)
            |> render("#{code}.json", reason: error, point: :user)
        end

      {:rate_limited, id, rate_limit_info} when id == batch_id ->
        conn
        |> merge_resp_headers([
          {"x-ratelimit-bucket", origin_hash},
          {"x-ratelimit-limit", get_in(rate_limit_info, [:limit]) |> to_string()},
          {"x-ratelimit-remaining", get_in(rate_limit_info, [:remaining]) |> to_string()},
          {"x-ratelimit-reset", get_in(rate_limit_info, [:reset]) |> to_string()}
        ])
        |> put_view(json: ExfwghtblogWeb.ErrorJSON)
        |> put_status(429)
        |> render("429.json")
    after
      3000 ->
        conn
        |> put_view(json: ExfwghtblogWeb.ErrorJSON)
        |> put_status(500)
        |> render("500.json")
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
