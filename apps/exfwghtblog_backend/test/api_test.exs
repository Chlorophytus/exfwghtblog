defmodule ExfwghtblogBackend.APITest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest ExfwghtblogBackend.API

  @opts ExfwghtblogBackend.API.init([])

  # ===========================================================================
  test "returns health check with HTTP 'GET' to /health" do
    conn = conn(:get, "/health")

    conn = ExfwghtblogBackend.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200
  end

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
  test "returns version info with HTTP 'GET' to /version" do
    conn = conn(:get, "/version")

    conn = ExfwghtblogBackend.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200
  end

  # ===========================================================================
  test "gets RSS feed with HTTP 'GET' to /rss"
end
