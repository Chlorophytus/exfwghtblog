defmodule ExfwghtblogFrontend.Connector do
  @moduledoc """
  This is the actual connection to the backend
  """
  def version() do
    uri =
      Application.get_env(:exfwghtblog_frontend, :backend_api_url)
      |> URI.new!()
      |> URI.append_path("/version")

    {:ok, response} = Req.get(uri)

    case response.status do
      status when status < 300 ->
        {:ok, %{status: status, result: response.body}}

      error ->
        {:error, %{status: error, result: response.body}}
    end
  end

  def whoami(token \\ nil) do
    uri =
      Application.get_env(:exfwghtblog_frontend, :backend_api_url)
      |> URI.new!()
      |> URI.append_path("/whoami")

    {:ok, response} = if is_nil token do
      Req.get(uri)
    else
      Req.get(uri, headers: [authorization: "Bearer " <> token])
    end

    case response.status do
      status when status < 300 ->
        {:ok, %{status: status, result: response.body}}

      error ->
        {:error, %{status: error, result: response.body}}
    end
  end

  def login(username, password) do
    uri =
      Application.get_env(:exfwghtblog_frontend, :backend_api_url)
      |> URI.new!()
      |> URI.append_path("/login")

    {:ok, response} = Req.post(uri, json: %{username: username, password: password})

    case response.status do
      status when status < 300 ->
        {:ok, %{status: status, result: response.body}}

      error ->
        {:error, %{status: error, result: response.body}}
    end
  end
end
