defmodule ExfwghtblogBackend.APILoginTest do
  use ExfwghtblogBackend.RepoCase
  use Plug.Test

  @opts ExfwghtblogBackend.API.init([])

  # ===========================================================================
  test "allows login with HTTP 'POST' /login" do
    ExfwghtblogBackend.Administration.new_user("test_user", "12345")

    conn =
      conn(
        :post,
        "/login",
        Jason.encode!(%{
          username: "test_user",
          password: "12345"
        })
      )
      |> put_req_header("content-type", "application/json")

    conn = ExfwghtblogBackend.API.call(conn, @opts)

    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "logged_in"
  end
end
