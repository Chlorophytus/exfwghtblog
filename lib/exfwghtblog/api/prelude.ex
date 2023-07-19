defmodule Exfwghtblog.API.Prelude do
  @moduledoc """
  Different convenience/prelude plugs
  """
  use Plug.Builder

  @doc """
  Sets the `Content-Type` header to `application/json`
  """
  def set_content_type(conn, _opts) do
    conn |> put_resp_content_type("application/json")
  end
end
