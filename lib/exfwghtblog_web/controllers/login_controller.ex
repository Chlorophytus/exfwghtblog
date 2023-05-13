defmodule ExfwghtblogWeb.LoginController do
  @moduledoc """
  Controller for rendering blog posts, and their previews
  """
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :controller

  @doc """
  Renders the login page
  """
  def login(conn, _params) do
    render(conn, :login)
  end

  @doc """
  Log out a user if they're logged in
  """
  def logout(conn, _params) do
    conn
    |> Exfwghtblog.Guardian.Plug.sign_out()
    |> put_flash(:info, gettext("Logged out successfully"))
    |> redirect(to: "/posts")
  end
end
