defmodule ExfwghtblogWeb.PostControllerMulti do
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
        |> render(:multi,
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
    {page, _garbage_data} = Integer.parse(conn.query_params["page"] || "0")

    batch_id = Exfwghtblog.BatchProcessor.post_read_multi(page)

    conn
    |> Plug.Conn.assign(:batch_id, batch_id)
  end
end
