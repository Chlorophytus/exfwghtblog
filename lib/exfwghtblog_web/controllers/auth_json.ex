defmodule ExfwghtblogWeb.AuthJSON do
  @moduledoc """
  JSON templates for logging in users
  """

  @doc """
  Successful login JSON
  """
  def render("200.json", _args) do
    %{
      ok: true
    }
  end
end
