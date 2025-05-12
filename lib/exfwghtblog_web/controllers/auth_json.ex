defmodule ExfwghtblogWeb.AuthJSON do
  @moduledoc """
  JSON templates for logging in users
  """

  @doc """
  Successful login JSON
  """
  def render("200.json", %{token: token}) do
    %{
      ok: true,
      token: token
    }
  end
end
