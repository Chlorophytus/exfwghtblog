defmodule ExfwghtblogWeb.ErrorJSON do
  @moduledoc """
  This module is invoked by your endpoint in case of errors on JSON requests.

  See config/config.exs.
  """

  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end
  # ===========================================================================
  # ERROR 400
  # ===========================================================================
  def render("400.json", _assigns) do
    %{ok: false, detail: "Bad request"}
  end

  # ===========================================================================
  # ERROR 401
  # ===========================================================================
  def render("401.json", %{point: :user, reason: :invalid_password}) do
    %{ok: false, detail: "Authentication failed"}
  end

  def render("401.json", %{point: :edit, reason: :not_your_entry}) do
    %{ok: false, detail: "This is not your post"}
  end

  def render("401.json", _assigns) do
    %{ok: false, detail: "Unauthorized"}
  end

  # ===========================================================================
  # ERROR 500
  # ===========================================================================
  def render("500.json", %{point: :user, reason: :does_not_exist}) do
    %{ok: false, detail: "User does not exist"}
  end

  def render("500.json", _assigns) do
    %{ok: false, detail: "Internal server error"}
  end

  # ===========================================================================
  # CATCHALL
  # ===========================================================================
  def render(template, _assigns) do
    %{ok: false, detail: Phoenix.Controller.status_message_from_template(template)}
  end
end
