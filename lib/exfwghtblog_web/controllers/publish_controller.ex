defmodule ExfwghtblogWeb.PublishController do
  @moduledoc """
  Controller for publishing blog posts
  """
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :controller

  defp map_error(:error), do: 500
  defp map_error(:not_your_entry), do: 401
  defp map_error(:not_logged_in), do: 401

  def publisher(conn, _params) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      render(conn, :publish)
    else
      conn
      |> put_flash(:error, gettext("You are not logged in"))
      |> redirect(to: "/posts")
    end
  end

  def edit(conn, %{"idx" => idx}) do
    user_id =
      if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
        conn |> Exfwghtblog.Guardian.Plug.current_resource()
      else
        nil
      end

    {:ok, body, conn} = conn |> read_body()

    origin_hash = Exfwghtblog.Batch.origin_hash(conn.remote_ip)
    batch_id = Exfwghtblog.Batch.try_revise_entry(user_id, idx, body, origin_hash)

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

        case batch_result.status do
          :ok ->
            conn
            |> put_view(json: ExfwghtblogWeb.PublishJSON)
            |> render(:edit_success)

          error ->
            code = map_error(error)

            conn
            |> put_view(json: ExfwghtblogWeb.ErrorJSON)
            |> put_status(code)
            |> render("#{code}.json", reason: error, point: :edit)
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

  def remove(conn, %{"idx" => idx}) do
    user_id =
      if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
        conn |> Exfwghtblog.Guardian.Plug.current_resource()
      else
        nil
      end

    origin_hash = Exfwghtblog.Batch.origin_hash(conn.remote_ip)
    batch_id = Exfwghtblog.Batch.try_delete_entry(user_id, idx, origin_hash)

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

        case batch_result.status do
          :ok ->
            conn
            |> put_view(json: ExfwghtblogWeb.PublishJSON)
            |> render(:delete_success)

          error ->
            code = map_error(error)

            conn
            |> put_view(json: ExfwghtblogWeb.ErrorJSON)
            |> put_status(code)
            |> render("#{code}.json", reason: error, point: :edit)
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

  def post(conn, %{"title" => title, "summary" => summary, "body" => body}) do
    post =
      if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
        %Exfwghtblog.Post{
          title: title,
          summary: summary,
          body: body,
          poster: conn |> Exfwghtblog.Guardian.Plug.current_resource()
        }
      else
        nil
      end

    origin_hash = Exfwghtblog.Batch.origin_hash(conn.remote_ip)
    batch_id = Exfwghtblog.Batch.publish_entry(post, origin_hash)

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

        case batch_result do
          {:ok, post} ->
            conn
            |> fetch_flash()
            |> put_flash(:info, gettext("Post #%{post_idx} success", post_idx: post.id))
            |> redirect(to: "/posts")

          :not_logged_in ->
            conn
            |> fetch_flash()
            |> put_flash(:error, gettext("You are not logged in"))
            |> redirect(to: "/posts")

          _ ->
            conn
            |> fetch_flash()
            |> put_flash(:error, gettext("Publishing failed"))
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
      3000 ->
        conn
        |> fetch_flash()
        |> put_flash(:error, gettext("Publishing failed"))
    end
  end
end
