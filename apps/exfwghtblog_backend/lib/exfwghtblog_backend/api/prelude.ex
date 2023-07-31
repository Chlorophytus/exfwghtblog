defmodule ExfwghtblogBackend.API.Prelude do
  @moduledoc """
  Different convenience/prelude plugs
  """
  use Plug.Builder
  require Logger

  @doc """
  Sets the `Content-Type` header to `application/json`
  """
  def set_content_type(conn, _opts) do
    conn |> put_resp_content_type("application/json")
  end

  @doc """
  Inserts the time the request was made to the `Plug.Conn` private store

  Useful to time the request latency
  """
  def inject_start_time(conn, _opts) do
    conn |> put_private(:start_time, DateTime.utc_now())
  end

  @doc """
  Logs the request.
  """
  def log_request(conn, level: level = _opts) do
    request_url = conn |> request_url()
    ip_addr = conn.remote_ip |> :inet.ntoa()

    Logger.log(
      level,
      "HTTP request received from #{ip_addr}:#{conn.port} [#{conn.method} #{request_url}]"
    )

    conn
  end
end
