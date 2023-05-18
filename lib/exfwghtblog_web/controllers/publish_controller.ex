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

  def edit(conn, %{"idx" => idx}) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

      {:ok, body, conn} = conn |> read_body()
      batch_id = Exfwghtblog.BatchProcessor.try_revise_entry(user.id, idx, body)

      receive do
        {:batch_done, id, batch_result} when id == batch_id ->
          case batch_result do
            {:batch_done, _id, %{status: :ok}} ->
              conn
              |> fetch_flash()
              |> put_flash(:info, gettext("Edit of post #%{post_idx} success", post_idx: idx))
              |> redirect(to: "/posts/#{idx}")

            {:batch_done, _id, %{status: :not_your_entry}} when id == batch_id ->
              conn
              |> fetch_flash()
              |> put_flash(
                :error,
                gettext("Edit of post #%{post_idx} failed, you can only edit your own posts.",
                  post_idx: idx
                )
              )

            _ ->
              conn
              |> fetch_flash()
              |> put_flash(:error, gettext("Edit of post #%{post_idx} failed", post_idx: idx))
          end
      after
        3000 ->
          conn
          |> fetch_flash()
          |> put_flash(:error, gettext("Edit of post #%{post_idx} failed", post_idx: idx))
      end
    else
      conn
      |> fetch_flash()
      |> put_flash(:error, gettext("You are not logged in"))
      |> redirect(to: "/posts")
    end
  end

  def remove(conn, %{"idx" => idx}) do
    if Exfwghtblog.Guardian.Plug.authenticated?(conn) do
      user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

      batch_id = Exfwghtblog.BatchProcessor.try_delete_entry(user.id, idx)

      receive do
        {:batch_done, id, batch_result} when id == batch_id ->
          case batch_result do
            {:batch_done, _id, %{status: :ok}} ->
              conn
              |> fetch_flash()
              |> put_flash(:info, gettext("Removal of post #%{post_idx} success", post_idx: idx))
              |> redirect(to: "/posts")

            {:batch_done, _id, %{status: :not_your_entry}} when id == batch_id ->
              conn
              |> fetch_flash()
              |> put_flash(
                :error,
                gettext(
                  "Removal of post #%{post_idx} failed, you can only remove your own posts.",
                  post_idx: idx
                )
              )

            _ ->
              conn
              |> fetch_flash()
              |> put_flash(:error, gettext("Removal of post #%{post_idx} failed", post_idx: idx))
          end
      after
        3000 ->
          conn
          |> fetch_flash()
          |> put_flash(:error, gettext("Removal of post #%{post_idx} failed", post_idx: idx))
      end
    else
      conn
      |> fetch_flash()
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
