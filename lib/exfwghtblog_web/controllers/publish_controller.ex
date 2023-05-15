defmodule ExfwghtblogWeb.PublishController do
  @moduledoc """
  Controller for publishing blog posts
  """
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :controller

  def publisher(conn, _params) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      render(conn, :publish)
    else
      conn
      |> put_flash(:error, gettext("You are not logged in"))
      |> redirect(to: "/posts")
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
          poster_id: user.id
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
