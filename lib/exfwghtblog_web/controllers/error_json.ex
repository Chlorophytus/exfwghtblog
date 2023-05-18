defmodule ExfwghtblogWeb.ErrorJSON do
  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  # ===========================================================================
  # ERROR 400
  # ===========================================================================
  def render("400.json", _assigns) do
    %{ok: false, detail: "Bad request"}
  end

  # ===========================================================================
  # ERROR 401
  # ===========================================================================
  def render("401.json", %{reason: :invalid_password}) do
    %{ok: false, detail: "Authentication failed"}
  end

  def render("401.json", _assigns) do
    %{ok: false, detail: "Unauthorized"}
  end

  # ===========================================================================
  # ERROR 500
  # ===========================================================================
  def render("500.json", %{reason: :does_not_exist}) do
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
