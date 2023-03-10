defmodule ExfwghtblogWeb.PageController do
  use ExfwghtblogWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
