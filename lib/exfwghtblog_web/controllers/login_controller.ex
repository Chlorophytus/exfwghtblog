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
    conn
    |> assign(:page_title, "Log In")
    |> render(:login)
  end

  @doc """
  Log out a user if they're logged in
  """
  def logout(conn, _params) do
    conn
    |> put_session(:exfwghtblog_token, nil)
    |> put_flash(:info, gettext("Logged out successfully"))
    |> redirect(to: "/posts")
  end
end
