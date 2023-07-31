defmodule ExfwghtblogBackend.API do
  @moduledoc """
  Router for HTTP REST-based API endpoints
  """
  @behaviour Guardian.Plug.ErrorHandler

  alias ExfwghtblogBackend.Guardian.Plug, as: Auth
  alias __MODULE__.Errors
  alias __MODULE__.Responses

  use Plug.Router
  use Plug.ErrorHandler

  import __MODULE__.Prelude, only: [set_content_type: 2, inject_start_time: 2, log_request: 2]
  import Ecto.Query

  require Logger

  plug(:inject_start_time)
  plug(RemoteIp)
  plug(:log_request, level: :info)

  plug(Guardian.Plug.VerifyHeader,
    claims: %{typ: "access"},
    module: ExfwghtblogBackend.Guardian,
    error_handler: __MODULE__
  )

  plug(:set_content_type)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  # ===========================================================================
  # Endpoints
  # ===========================================================================
  get "/health" do
    {:ok, json} =
      Responses.map_json(:health_check)
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    conn |> send_resp(200, json)
  end

  get "/version" do
    {:ok, json} =
      Responses.map_json(:version)
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    conn |> send_resp(200, json)
  end

  post "/login" do
    user =
      ExfwghtblogBackend.Repo.one(
        from(u in ExfwghtblogBackend.Repo.User,
          where: ilike(u.username, ^conn.body_params["username"]),
          select: u
        )
      )

    cond do
      is_nil(user) ->
        Argon2.no_user_verify()

        {:ok, json} =
          Errors.map_json(401, %{message: "User does not exist"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)

      Argon2.verify_pass(conn.body_params["password"], user.pass_hash) ->
        conn =
          conn
          |> Auth.sign_in(user, %{typ: "access"},
            ttl: {Application.fetch_env!(:exfwghtblog_backend, :session_ttl_minutes), :minute}
          )

        token = conn |> Auth.current_token()

        {:ok, json} =
          Responses.map_json({:logged_in, token})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(200, json)

      true ->
        {:ok, json} =
          Errors.map_json(401, %{message: "Incorrect password"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)
    end
  end

  post "/logout" do
    conn = conn |> Auth.sign_out()

    {:ok, json} =
      Responses.map_json(:logged_out)
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    conn |> send_resp(200, json)
  end

  post "/publish" do
    conn = conn |> handle_auth()

    if conn.halted do
      conn
    else
      title = conn.body_params["title"] || ""
      summary = conn.body_params["summary"] || ""
      body = conn.body_params["body"] || ""

      title_limit = Application.fetch_env!(:exfwghtblog_backend, :title_limit)
      summary_limit = Application.fetch_env!(:exfwghtblog_backend, :summary_limit)
      body_limit = Application.fetch_env!(:exfwghtblog_backend, :body_limit)

      if Enum.all?([
           title != "",
           summary != "",
           body != "",
           String.length(title) <= title_limit,
           String.length(summary) <= summary_limit,
           String.length(body) <= body_limit
         ]) do

        {:ok, poster, _claims} = conn |> Auth.current_token() |> ExfwghtblogBackend.Guardian.resource_from_token()

        post = %ExfwghtblogBackend.Repo.Post{
          poster: poster,
          deleted: false,
          title: title,
          summary: summary,
          body: body
        }

        case ExfwghtblogBackend.Repo.insert(post) do
          {:ok, result} ->
            {:ok, json} =
              Responses.map_json({:published, result.id})
              |> Responses.add_response_time(conn.private.start_time)
              |> Jason.encode()

            conn |> send_resp(201, json)

          _ ->
            {:ok, json} =
              Errors.map_json(500)
              |> Responses.add_response_time(conn.private.start_time)
              |> Jason.encode()

            conn |> send_resp(500, json)
        end
      else
        {:ok, json} =
          Errors.map_json(400, %{
            message: "Body, summary, or title is either too short or too long"
          })
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(400, json)
      end
    end
  end

  # Post list
  get "/posts" do
    # Get the page
    {page, _garbage_data} = Integer.parse(conn.query_params["page"] || "0")

    # Set pages' post counts
    post_fetch_count = Application.get_env(:exfwghtblog_backend, :post_fetch_count)

    # How many posts in the database?
    all_count = ExfwghtblogBackend.Repo.aggregate(ExfwghtblogBackend.Repo.Post, :count)

    # Okay, how many pages in total?
    page_count = div(all_count, post_fetch_count) + 1

    # Okay, post offset?
    page_offset = all_count - page * post_fetch_count

    page_contents =
      ExfwghtblogBackend.Repo.all(
        from(p in ExfwghtblogBackend.Repo.Post,
          order_by: [desc: p.id],
          where: p.id <= ^page_offset,
          limit: ^post_fetch_count,
          preload: [:poster]
        )
      )

    page_data =
      page_contents
      |> Enum.map(fn post ->
        if post.deleted do
          %{id: post.id, deleted: true}
        else
          %{
            id: post.id,
            deleted: false,
            summary: post.summary,
            inserted_at: post.inserted_at |> NaiveDateTime.to_string(),
            updated_at: post.updated_at |> NaiveDateTime.to_string(),
            poster: post.poster.username
          }
        end
      end)

    {:ok, json} =
      Responses.map_json({:page, page_count, page_data})
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    conn |> send_resp(200, json)
  end

  # Post view
  get "/posts/:id_string" do
    {id, _garbage_data} = Integer.parse(id_string || "0")

    post =
      ExfwghtblogBackend.Repo.one(
        from(p in ExfwghtblogBackend.Repo.Post, where: p.id == ^id, preload: [:poster])
      )

    case post do
      nil ->
        {:ok, json} =
          Errors.map_json(404, %{message: "That post doesn't exist"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(404, json)

      %ExfwghtblogBackend.Repo.Post{deleted: true} ->
        {:ok, json} =
          Errors.map_json(410, %{message: "The poster has deleted this post"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(410, json)

      %ExfwghtblogBackend.Repo.Post{
        deleted: false,
        summary: summary,
        inserted_at: inserted_at,
        updated_at: updated_at,
        poster: poster
      } ->
        {:ok, json} =
          Responses.map_json(
            {:post,
             %{
               summary: summary,
               inserted_at: inserted_at |> NaiveDateTime.to_string(),
               updated_at: updated_at |> NaiveDateTime.to_string(),
               poster: poster.username
             }}
          )
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(200, json)
    end
  end

  # TODO: Post edit
  # TODO: Post delete

  match _ do
    {:ok, json} =
      Errors.map_json(501)
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    # Return HTTP 501 in JSON for unimplemented endpoints
    conn |> send_resp(501, json)
  end

  # ===========================================================================
  # Circumstantial Handlers
  # ===========================================================================
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack} = fail_info) do
    # Return HTTP 500 in JSON upon an error condition
    Logger.info("PLUG FAIL #{inspect(fail_info)}")

    {:ok, json} =
      Errors.map_json(500)
      |> Responses.add_response_time(conn.private.start_time)
      |> Jason.encode()

    conn |> send_resp(500, json)
  end

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, _reason} = fail_info, _opts) do
    Logger.info("AUTHENTICATION FAIL #{inspect(fail_info)}")

    case type do
      :unauthorized ->
        {:ok, json} =
          Errors.map_json(401, %{message: "You are not logged in"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)

      :invalid_token ->
        {:ok, json} =
          Errors.map_json(401, %{message: "Invalid authentication token"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)

      :already_authenticated ->
        {:ok, json} =
          Errors.map_json(400, %{message: "You are already logged in"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(400, json)

      :no_resource_found ->
        {:ok, json} =
          Errors.map_json(401, %{message: "No user resource found"})
          |> Responses.add_response_time(conn.private.start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)
    end
  end

  defp handle_auth(conn) do
    logged_in? = conn |> Auth.authenticated?()

    if logged_in? do
      conn
    else
      {:ok, json} =
        Errors.map_json(401, %{message: "You are not logged in"})
        |> Responses.add_response_time(conn.private.start_time)
        |> Jason.encode()

      conn |> send_resp(401, json) |> halt
      conn
    end
  end
end
