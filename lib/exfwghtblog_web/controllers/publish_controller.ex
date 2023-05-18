defmodule ExfwghtblogWeb.PublishController do
  @moduledoc """
  Controller for publishing blog posts
  """
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :controller

  defp map_error(:error), do: 500
  defp map_error(:not_your_entry), do: 401

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
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

      {:ok, body, conn} = conn |> read_body()

      batch_id = Exfwghtblog.BatchProcessor.try_revise_entry(user.id, idx, body)

      receive do
        {:batch_done, id, batch_result} when id == batch_id ->
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
      after
        3000 ->
          conn
          |> put_view(json: ExfwghtblogWeb.ErrorJSON)
          |> put_status(500)
          |> render("500.json")
      end
    else
      conn
      |> put_view(json: ExfwghtblogWeb.ErrorJSON)
      |> put_status(401)
      |> render("401.json")
    end
  end

  def remove(conn, %{"idx" => idx}) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

      batch_id = Exfwghtblog.BatchProcessor.try_delete_entry(user.id, idx)

      receive do
        {:batch_done, id, batch_result} when id == batch_id ->
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
      after
        3000 ->
          conn
          |> put_view(json: ExfwghtblogWeb.ErrorJSON)
          |> put_status(500)
          |> render("500.json")
      end
    else
      conn
      |> put_view(json: ExfwghtblogWeb.ErrorJSON)
      |> put_status(401)
      |> render("401.json")
    end
  end

  def post(conn, %{"title" => title, "summary" => summary, "body" => body}) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

      batch_id =
        Exfwghtblog.BatchProcessor.publish_entry(%Exfwghtblog.Post{
          title: title,
          summary: summary,
          body: body,
          poster: user
        })

      receive do
        {:batch_done, id, batch_result} when id == batch_id ->
          case batch_result do
            {:ok, post} ->
              conn
              |> fetch_flash()
              |> put_flash(:info, gettext("Post #%{post_idx} success", post_idx: post.id))
              |> redirect(to: "/posts")

            _ ->
              conn
              |> fetch_flash()
              |> put_flash(:error, gettext("Publishing failed"))
          end
      after
        3000 ->
          conn
          |> fetch_flash()
          |> put_flash(:error, gettext("Publishing failed"))
      end
    else
      conn
      |> fetch_flash()
      |> put_flash(:error, gettext("You are not logged in"))
      |> redirect(to: "/posts")
    end
  end
end
