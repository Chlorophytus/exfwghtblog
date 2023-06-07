defmodule ExfwghtblogWeb.ErrorController do
  @moduledoc """
  Shortcut controller for rendering errors
  """
  use ExfwghtblogWeb, :controller

  @doc """
  A plug error for rate limited users
  """
  def rate_limited(conn, _opts) do
    conn |> put_view(html: ExfwghtblogWeb.ErrorHTML) |> render("429.html") |> halt()
  end
  def rate_limited_json(conn, _opts) do
    Process.sleep(1000)
    conn |> put_view(json: ExfwghtblogWeb.ErrorJSON) |> render("429.json") |> halt()
  end
end
