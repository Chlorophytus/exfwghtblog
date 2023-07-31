defmodule ExfwghtblogBackend.APIMutabilityTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts ExfwghtblogBackend.API.init([])
  @publish_amount 4

  defp create_and_log_in() do
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

    response["token"]
  end

  defp publish_many(token) do
    for id <- 1..@publish_amount do
      conn =
        conn(
          :post,
          "/publish",
          Jason.encode!(%{
            title: "Test title #{inspect(id)}",
            summary: "Test summary #{inspect(id)}",
            body: "Test post #{inspect(id)}"
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
  setup_all tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExfwghtblogBackend.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ExfwghtblogBackend.Repo, {:shared, self()})
    end

    token = create_and_log_in()
    token |> publish_many()
    [token: token]
  end

  # ===========================================================================
  test "allows HTTP 'GET' to /posts (multi view)" do
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

  # ===========================================================================
  test "allows HTTP 'GET' to /posts/1 (single view)" do
    conn = conn(:get, "/posts/1")
    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "post"
    assert response["data"]["body"] == "Test post 1"
  end

  # ===========================================================================
  test "allows HTTP 'PUT' to /posts/2 (single edit)", %{token: token} do
    conn =
      conn(
        :put,
        "/posts/2",
        Jason.encode!(%{
          body: "Hey, a new body!"
        })
      )
      |> put_req_header("authorization", "Bearer " <> token)
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
    assert response["status"] == "revised"
    # =========================================================================
    # Check for edits
    conn = conn(:get, "/posts/2")
    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "post"
    assert response["data"]["body"] == "Hey, a new body!"
  end

  # ===========================================================================
  test "allows HTTP 'DELETE' to /posts/3 (single delete)", %{token: token} do
    conn =
      conn(:delete, "/posts/3")
      |> put_req_header("authorization", "Bearer " <> token)
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
    assert response["status"] == "deleted"
    # =========================================================================
    # Check for edits
    conn = conn(:get, "/posts/3")
    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Does our response indicate deletion?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 410
  end

  # ===========================================================================
  test "allows HTTP 'GET' /whoami (logged in user)", %{token: token} do
    conn =
      conn(:get, "/whoami")
      |> put_req_header("authorization", "Bearer " <> token)

    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "whoami"
    assert response["username"] == "test_user"
  end

  test "allows HTTP 'GET' /whoami (anonymous user)" do
    conn = conn(:get, "/whoami")

    conn = ExfwghtblogBackend.API.call(conn, @opts)
    [content_type] = conn |> get_resp_header("content-type")

    # Is our response well-formed, first of all?
    assert conn.state == :sent
    assert content_type |> String.contains?("application/json")
    assert conn.status == 200

    # Make sure the response structure is well-formed
    {:ok, response} = Jason.decode(conn.resp_body)
    assert response["e"] == "ok"
    assert response["status"] == "whoami"
    assert is_nil(response["username"])
  end
end
