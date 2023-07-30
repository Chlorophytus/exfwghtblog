defmodule ExfwghtblogBackend.APIHealthTest do
  use ExUnit.Case, async: true
  use Plug.Test

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
end
