defmodule ExfwghtblogBackend.APITest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest ExfwghtblogBackend.API

  @opts ExfwghtblogBackend.API.init([])

  # ===========================================================================
  test "returns HTTP 501 status when requesting unimplemented endpoints" do
    conn = conn(:get, "/invalid")

    conn = ExfwghtblogBackend.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 501
  end

  # ===========================================================================
  test "allows publishing with HTTP 'POST' to /publish, returns post ID"
  test "allows editing post ID 'N' content with HTTP 'PUT' to /posts/N"
  test "allows deleting post ID 'N' content with HTTP 'DELETE' to /posts/N"
  test "allows fetching RSS feed with HTTP 'GET' to /rss"
  test "allows fetching post list with HTTP 'GET' to /posts"
  test "allows fetching post ID 'N' with HTTP 'GET' to /posts/N"
end
