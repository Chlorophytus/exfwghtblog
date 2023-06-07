defmodule ExfwghtblogWeb.PostControllerMulti do
  @moduledoc """
  Controller for rendering multiple blog posts' pages
  """
  use ExfwghtblogWeb, :controller

  plug Hammer.Plug,
    rate_limit: {"post:load_multi", 5_000, 2},
    on_deny: &ExfwghtblogWeb.ErrorController.rate_limited/2

  plug :preload

  # ===========================================================================
  # Load page
  # ===========================================================================
  @doc """
  Renders the page
  """
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

  # ===========================================================================
  # Pre-load validation
  # ===========================================================================
  defp preload(conn, _options) do
    {page, _garbage_data} = Integer.parse(conn.query_params["page"] || "0")

    batch_id = Exfwghtblog.BatchProcessor.load_page(page)

    conn
    |> Plug.Conn.assign(:batch_id, batch_id)
  end
end
