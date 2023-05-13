defmodule ExfwghtblogWeb.PostControllerSingle do
  @moduledoc """
  Controller for rendering multiple blog posts' previews
  """
  use ExfwghtblogWeb, :controller

  plug :preload

  def show(conn, _params) do
    batch_id = conn.assigns[:batch_id]

    receive do
      {:batch_done, id, batch_result} when id == batch_id ->
        conn
        |> put_view(html: ExfwghtblogWeb.PostHTML)
        |> render(:single,
          batch_result: batch_result,
          signed_in: Exfwghtblog.Guardian.Plug.authenticated?(conn)
        )
    after
      2000 ->
        conn
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> render("500.html")
    end
  end

  defp preload(conn, _options) do
    conn = conn |> fetch_query_params()

    case Integer.parse(conn.params["idx"]) do
      {idx, ""} ->
        batch_id = Exfwghtblog.BatchProcessor.post_read_single(idx)

        conn
        |> Plug.Conn.assign(:batch_id, batch_id)

      _ ->
        conn
        |> put_view(html: ExfwghtblogWeb.ErrorHTML)
        |> render("400.html")
        |> halt()
    end
  end
end
