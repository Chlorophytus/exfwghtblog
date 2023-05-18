defmodule ExfwghtblogWeb.AuthJSON do
  @moduledoc """
  JSON templates for logging in users
  """

  @doc """
  Successful login JSON
  """
  def login_success(%{token: token}) do
    %{
      ok: true,
      ttl: ExfwghtblogWeb.AuthController.get_ttl_minutes(),
      token: token
    }
  end
end
