defmodule ExfwghtblogBackend.APIMutabilityTest do
  use ExfwghtblogBackend.RepoCase, async: true
  use Plug.Test

  @opts ExfwghtblogBackend.API.init([])
  @publish_amount 4

  defp create_and_log_in() do
    test_username = :crypto.hash(:sha3_256, :erlang.unique_integer() |> to_string) |> Base.encode16
    ExfwghtblogBackend.Administration.new_user(test_username, "12345")

    conn =
      conn(
        :post,
        "/login",
        Jason.encode!(%{
          username: test_username,
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

    response["token"]
  end

  defp publish_many(token) do
    for id <- 1..@publish_amount do
      conn =
        conn(
          :post,
          "/publish",
          Jason.encode!(%{
            title: "Test post #{inspect id}",
            summary: "Test summary",
            body: "This is post ##{inspect id}!"
          })
        )
        |> put_req_header("content-type", "application/json")
        |> put_req_header("authorization", "Bearer " <> token)

      conn = ExfwghtblogBackend.API.call(conn, @opts)

      [content_type] = conn |> get_resp_header("content-type")

      # Is our response well-formed, first of all?
      assert conn.state == :sent
      assert content_type |> String.contains?("application/json")
      assert conn.status == 201

      # Make sure the response structure is well-formed
      {:ok, response} = Jason.decode(conn.resp_body)
      assert response["e"] == "ok"
      assert response["status"] == "published"
    end
  end
  # ===========================================================================
  test "allows login with HTTP 'POST' /login" do
    create_and_log_in()
  end

  test "allows publishing with HTTP 'POST' to /publish, and fetching post list with HTTP 'GET' to /posts" do
    create_and_log_in() |> publish_many()

    conn = conn(:get, "/posts?page=0")
    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "page"
    assert length(response["data"]) == @publish_amount
  end
end
