defmodule ExfwghtblogWeb.PageController do
  use ExfwghtblogWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn
    |> assign(:page_title, "Home")
    |> render(:home)
  end
end
