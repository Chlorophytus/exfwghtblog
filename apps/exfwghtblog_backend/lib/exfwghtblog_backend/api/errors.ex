defmodule ExfwghtblogBackend.API.Errors do
  @moduledoc """
  Static error responses sent as needed
  """

  @doc """
  Maps an HTTP error code to a static response

  Options can be supplied
  - `message`: A human-readable error message
  """
  def map_json(code), do: map_json(code, nil)
  # ===========================================================================
  # 400 Bad Request
  def map_json(400, %{message: message}) do
    %{e: :bad_request, message: message}
  end

  def map_json(400, _opts) do
    %{e: :bad_request, message: "400 Bad Request"}
  end

  # ===========================================================================
  # 401 Unauthorized
  def map_json(401, %{message: message}) do
    %{e: :unauthorized, message: message}
  end

  def map_json(401, _opts) do
    %{e: :unauthorized, message: "401 Unauthorized"}
  end

  # ===========================================================================
  # 403 Forbidden
  def map_json(403, %{message: message}) do
    %{e: :forbidden, message: message}
  end

  def map_json(403, _opts) do
    %{e: :forbidden, message: "403 Forbidden"}
  end

  # ===========================================================================
  # 404 Not Found
  def map_json(404, %{message: message}) do
    %{e: :not_found, message: message}
  end

  def map_json(404, _opts) do
    %{e: :not_found, message: "404 Not Found"}
  end

  # ===========================================================================
  # 410 Gone
  def map_json(410, %{message: message}) do
    %{e: :gone, message: message}
  end

  def map_json(410, _opts) do
    %{e: :gone, message: "410 Gone"}
  end

  # ===========================================================================
  # 500 Internal Server Error
  def map_json(500, %{message: message}) do
    %{e: :internal_server_error, message: message}
  end

  def map_json(500, _opts) do
    %{e: :internal_server_error, message: "500 Internal Server Error"}
  end

  # ===========================================================================
  # 501 Not Implemented
  def map_json(501, %{message: message}) do
    %{e: :not_implemented, message: message}
  end

  def map_json(501, _opts) do
    %{e: :not_implemented, message: "501 Not Implemented"}
  end

  # ===========================================================================
  # Unknown HTTP error code
  def map_json(_code, %{message: message}) do
    %{e: :unknown, message: message}
  end

  def map_json(_code, _opts) do
    %{e: :unknown, message: "Unhandled Server Error"}
  end
end
