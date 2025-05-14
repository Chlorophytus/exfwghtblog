defmodule ExfwghtblogWeb.PostControllerEditor do
  @moduledoc """
  Controller for rendering the blog post editor
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
      {:batch_done, id, batch_result} when id == batch_id ->
        resource = conn.assigns[:user_or_error]

        case resource do
          user_id when is_integer(user_id) ->
            conn
            |> render_result(batch_result, user_id)

          _ ->
            conn
            |> put_status(401)
            |> put_view(html: ExfwghtblogWeb.ErrorHTML)
            |> render("401.html")
            |> put_flash(:error, "You are not logged in")
        end
    after
      2000 ->
        conn
        |> put_status(500)
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> render("500.html")
    end
  end

  # ===========================================================================
  # Pre-load validation
  # ===========================================================================
  defp preload(conn, _options) do
    conn = conn |> fetch_query_params()

    case Integer.parse(conn.params["idx"]) do
      {idx, ""} ->
        batch_id = Exfwghtblog.BatchProcessor.load_post(idx)

        conn
        |> Plug.Conn.assign(:batch_id, batch_id)

      _ ->
        conn
        |> put_status(400)
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> render("400.html")
        |> halt()
    end
  end

  # ===========================================================================
  # Actual rendering of single posts or error pages
  # ===========================================================================
  defp render_result(conn, nil, _user_id) do
    conn
    |> put_status(404)
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> put_flash(:error, "The post could not be found")
    |> render("404.html")
  end

  defp render_result(conn, %Exfwghtblog.Post{deleted: true}, _user_id) do
    conn
    |> put_status(410)
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> put_flash(:error, "This post has been deleted")
    |> render("410.html")
  end

  defp render_result(conn, batch_result, user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.PostHTML)
    |> assign(:page_title, "Edit Post")
    |> render(:editor,
      batch_result: batch_result,
      user_id: user_id
    )
  end
end
