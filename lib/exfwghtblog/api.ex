defmodule Exfwghtblog.API do
  @moduledoc """
  Router for HTTP REST-based API endpoints
  """
  alias Exfwghtblog.Guardian.Plug, as: Auth
  alias __MODULE__.Errors
  alias __MODULE__.Responses

  use Plug.Router
  use Plug.ErrorHandler

  import __MODULE__.Prelude, only: [set_content_type: 2]
  import Ecto.Query

  plug(Guardian.Plug.VerifyHeader, claims: %{typ: "access"})
  plug(:set_content_type)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:match)
  plug(:dispatch)

  # ===========================================================================
  # Endpoints
  # ===========================================================================
  get "/health" do
    # {:ok, json} =
    start_time = DateTime.utc_now()

    {:ok, json} =
      Responses.map_json(:health_check)
      |> Responses.add_response_time(start_time)
      |> Jason.encode()

    conn |> send_resp(200, json)
  end

  get "/version" do
    # {:ok, json} =
    start_time = DateTime.utc_now()

    {:ok, json} =
      Responses.map_json(:version) |> Responses.add_response_time(start_time) |> Jason.encode()

    conn |> send_resp(200, json)
  end

  post "/login" do
    start_time = DateTime.utc_now()

    user =
      Exfwghtblog.Repo.one(
        from(u in Exfwghtblog.Repo.User,
          where: ilike(u.username, ^conn.body_params["username"]),
          select: u
        )
      )

    cond do
      is_nil(user) ->
        Argon2.no_user_verify()

        {:ok, json} =
          Errors.map_json(401, %{message: "User does not exist"})
          |> Responses.add_response_time(start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)

      Argon2.verify_pass(conn.body_params["password"], user.pass_hash) ->
        conn
        |> Auth.sign_in(%{
          ttl: {Application.fetch_env!(:exfwghtblog, :session_ttl_minutes), :minutes}
        })

        token = conn |> Auth.current_token()

        {:ok, json} =
          Responses.map_json({:logged_in, token})
          |> Responses.add_response_time(start_time)
          |> Jason.encode()

        conn |> send_resp(200, json)

      true ->
        {:ok, json} =
          Errors.map_json(401, %{message: "Incorrect password"})
          |> Responses.add_response_time(start_time)
          |> Jason.encode()

        conn |> send_resp(401, json)
    end
  end

  post "/logout" do
    start_time = DateTime.utc_now()
    conn = conn |> Auth.sign_out()

    {:ok, json} =
      Responses.map_json(:logged_out) |> Responses.add_response_time(start_time) |> Jason.encode()

    conn |> send_resp(200, json)
  end

  post "/publish" do
    start_time = DateTime.utc_now()

    conn = conn |> handle_auth(start_time)

    if conn.halted do
      {:ok, json} =
        Errors.map_json(400, %{
          message: "Body, summary, or title is either too short or too long"
        })
        |> Responses.add_response_time(start_time)
        |> Jason.encode()

      conn |> send_resp(400, json)
    else
      title = conn.body_params["title"] || ""
      summary = conn.body_params["summary"] || ""
      body = conn.body_params["body"] || ""

      title_limit = Application.fetch_env!(:exfwghtblog, :title_limit)
      summary_limit = Application.fetch_env!(:exfwghtblog, :summary_limit)
      body_limit = Application.fetch_env!(:exfwghtblog, :body_limit)

      if Enum.all?([
           title != "",
           summary != "",
           body != "",
           length(title) <= title_limit,
           length(summary) <= summary_limit,
           length(body) <= body_limit
         ]) do
        poster = conn |> Auth.current_resource()

        post = %Exfwghtblog.Repo.Post{
          poster: poster,
          deleted: false,
          title: title,
          summary: summary,
          body: body
        }

        case Exfwghtblog.Repo.insert(post) do
          {:ok, result} ->
            {:ok, json} =
              Responses.map_json({:published, result.id})
              |> Responses.add_response_time(start_time)
              |> Jason.encode()

            conn |> send_resp(202, json)

          _ ->
            {:ok, json} =
              Errors.map_json(500) |> Responses.add_response_time(start_time) |> Jason.encode()

            conn |> send_resp(500, json)
        end
      end
    else
      {:ok, json} =
        Errors.map_json(500) |> Responses.add_response_time(start_time) |> Jason.encode()

      conn |> send_resp(500, json)
    end
  end

  # TODO: Post view
  # TODO: Post list
  # TODO: Post edit
  # TODO: Post delete

  match _ do
    start_time = DateTime.utc_now()

    {:ok, json} =
      Errors.map_json(501) |> Responses.add_response_time(start_time) |> Jason.encode()

    # Return HTTP 501 in JSON for unimplemented endpoints
    conn |> send_resp(501, json)
  end

  # ===========================================================================
  # Circumstantial Handlers
  # ===========================================================================
  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    start_time = DateTime.utc_now()
    # Return HTTP 500 in JSON upon an error condition
    {:ok, json} =
      Errors.map_json(500) |> Responses.add_response_time(start_time) |> Jason.encode()

    conn |> send_resp(500, json)
  end

  defp handle_auth(conn, start_time) do
    logged_in? = conn |> Auth.authenticated?()

    if logged_in? do
      conn
    else
      {:ok, json} =
        Errors.map_json(401, %{message: "You are not logged in"})
        |> Responses.add_response_time(start_time)
        |> Jason.encode()

      conn |> send_resp(401, json) |> halt
      conn
    end
  end
end
