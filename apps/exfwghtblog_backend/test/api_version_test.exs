defmodule ExfwghtblogBackend.APIVersionTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts ExfwghtblogBackend.API.init([])

  # ===========================================================================
  test "returns version info with HTTP 'GET' to /version" do
    conn = conn(:get, "/version")

    conn = ExfwghtblogBackend.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200
  end
end
