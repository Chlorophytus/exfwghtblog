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
            |> put_view(html: ExfwghtblogWeb.ErrorHTML)
            |> render("401.html")
            |> put_flash(:error, "You are not logged in")
        end
    after
      2000 ->
        conn
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
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> render("400.html")
        |> halt()
    end
  end

  # ===========================================================================
  # Actual rendering of single posts or error pages
  # ===========================================================================
  defp render_result(conn, %{status: :ok} = batch_result, user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.PostHTML)
    |> render(:editor,
      batch_result: batch_result,
      user_id: user_id
    )
  end

  defp render_result(conn, %{status: :deleted}, _user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> render("410.html")
  end

  defp render_result(conn, %{status: :not_found}, _user_id) do
    conn
    |> put_view(html: ExfwghtblogWeb.ErrorHTML)
    |> render("404.html")
  end
end
