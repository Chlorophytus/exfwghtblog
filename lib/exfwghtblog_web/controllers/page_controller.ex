defmodule ExfwghtblogWeb.PageController do
  use ExfwghtblogWeb, :controller

  def home(conn, _params) do
    conn
    |> assign(:page_title, "Home")
    |> render(:home)
  end
end
