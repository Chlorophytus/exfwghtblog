defmodule Exfwghtblog.APITest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest Exfwghtblog.API

  @opts Exfwghtblog.API.init([])
  # ===========================================================================
  test "returns HTTP 501 status when requesting unimplemented endpoints" do
    conn = conn(:get, "/invalid")

    conn = Exfwghtblog.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 501
  end

  # ===========================================================================
  test "returns version info with HTTP 'GET' to /version" do
    conn = conn(:get, "/version")

    conn = Exfwghtblog.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200
  end

  # ===========================================================================
  test "returns health check with HTTP 'GET' to /health" do
    conn = conn(:get, "/health")

    conn = Exfwghtblog.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200
  end

  # ===========================================================================
  test "allows login with HTTP 'POST'/login"
  test "allows publishing with HTTP 'POST' to /publish, returns post ID"

  test "allows editing post ID 'N' content with HTTP 'PUT' to /posts/N"
  test "allows deleting post ID 'N' content with HTTP 'DELETE' to /posts/N"

  test "allows fetching RSS feed with HTTP 'GET' to /rss"

  test "allows fetching post list with HTTP 'GET' to /posts"
  test "allows fetching post ID 'N' with HTTP 'GET' to /posts/N"
end
