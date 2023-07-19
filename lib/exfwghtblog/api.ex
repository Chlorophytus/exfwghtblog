defmodule Exfwghtblog.API do
  @moduledoc """
  Endpoint, HTTP REST-based
  """
  alias __MODULE__.Errors
  alias __MODULE__.Responses
  use Plug.Router
  use Plug.ErrorHandler
  import __MODULE__.Prelude, only: [set_content_type: 2]

  plug(:set_content_type)
  plug(:match)
  plug(:dispatch)

  get "/health" do
    #{:ok, json} =
    start_time = DateTime.utc_now()
    {:ok, json} = Responses.map_json(:health_check) |> Responses.add_response_time(start_time) |> Jason.encode()
    conn |> send_resp(200, json)
  end

  get "/version" do
    #{:ok, json} =
    start_time = DateTime.utc_now()
    {:ok, json} = Responses.map_json(:version) |> Responses.add_response_time(start_time) |> Jason.encode()
    conn |> send_resp(200, json)
  end

  match(_) do
    start_time = DateTime.utc_now()
    {:ok, json} = Errors.map_json(501) |> Responses.add_response_time(start_time) |> Jason.encode()
    # Return HTTP 501 in JSON for unimplemented endpoints
    conn |> send_resp(501, json)
  end

  @impl Plug.ErrorHandler
  def handle_errors(conn, %{kind: _kind, reason: _reason, stack: _stack}) do
    start_time = DateTime.utc_now()
    # Return HTTP 500 in JSON upon an error condition
    {:ok, json} = Errors.map_json(500) |> Responses.add_response_time(start_time) |> Jason.encode()
    conn |> send_resp(500, json)
  end
end
