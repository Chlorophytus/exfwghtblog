defmodule ExfwghtblogWeb.PostController do
  @moduledoc """
  Controller for rendering blog posts, and their previews
  """
  use ExfwghtblogWeb, :controller

  @doc """
  Render a single blog post on one page
  """
  def single(conn, %{"idx" => idx}) do
    render(conn, :single, idx: idx)
  end

  @doc """
  Render multiple post previews on one page
  """
  def multi(conn, _params) do
    # page defaults to 0
    {page, _garbage_data} = Integer.parse(conn.query_params["page"] || "0")

    render(conn, :multi, page: page)
  end
end
