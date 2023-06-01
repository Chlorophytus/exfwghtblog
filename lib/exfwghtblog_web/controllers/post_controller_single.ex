defmodule ExfwghtblogWeb.PostControllerSingle do
  @moduledoc """
  Controller for rendering actual single blog posts
  """
  use ExfwghtblogWeb, :controller

  plug :preload

  # ===========================================================================
  # Load page
  # ===========================================================================
  @doc """
  Renders the post
  """
  def show(conn, _params) do
    batch_id = conn.assigns[:batch_id]

    receive do
      {:batch_done, id, rate_limit_info, batch_result} when id == batch_id ->
        conn =
          conn
          |> merge_resp_headers([
            {"x-ratelimit-bucket", origin_hash},
            {"x-ratelimit-limit", get_in(rate_limit_info, [:limit]) |> to_string()},
            {"x-ratelimit-remaining", get_in(rate_limit_info, [:remaining]) |> to_string()},
            {"x-ratelimit-reset", get_in(rate_limit_info, [:reset]) |> to_string()}
          ])

        resource =
          conn
          |> Exfwghtblog.Guardian.Plug.current_token()
          |> Exfwghtblog.Guardian.resource_from_token()

        case resource do
          {:ok, user, _claims} ->
            conn
            |> render_result(batch_result, user.id)

          _ ->
            conn
            |> render_result(batch_result, nil)
        end

      {:rate_limited, id, rate_limit_info} when id == batch_id ->
        conn
        |> merge_resp_headers([
          {"x-ratelimit-bucket", origin_hash},
          {"x-ratelimit-limit", get_in(rate_limit_info, [:limit]) |> to_string()},
          {"x-ratelimit-remaining", get_in(rate_limit_info, [:remaining]) |> to_string()},
          {"x-ratelimit-reset", get_in(rate_limit_info, [:reset]) |> to_string()}
        ])
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> put_status(429)
        |> render("429.html")
    after
      2000 ->
        conn
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> put_status(500)
        |> render("500.html")
    end
  end

  # ===========================================================================
  # Pre-load validation
  # ===========================================================================
  defp preload(conn, _options) do
    origin_hash = Exfwghtblog.Batch.origin_hash(conn.remote_ip)
    conn = conn |> fetch_query_params()

    idx =
      case Integer.parse(conn.params["idx"]) do
        {idx, ""} -> idx
        _ -> nil
      end

    batch_id = Exfwghtblog.Batch.load_post(idx, origin_hash)

    conn
    |> Plug.Conn.assign(:batch_id, batch_id)
  end

  # ===========================================================================
  # Actual rendering of single posts or error pages
  # ===========================================================================
  defp render_result(conn, nil, _user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> put_flash(:error, "The post could not be found")
    |> put_status(404)
    |> render("404.html")
  end

  defp render_result(conn, %Exfwghtblog.Post{deleted: true}, _user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> put_flash(:error, "This post has been deleted")
    |> put_status(410)
    |> render("410.html")
  end

  defp render_result(conn, batch_result, user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.PostHTML)
    |> render(:single,
      batch_result: batch_result,
      user_id: user_id
    )
  end
end
