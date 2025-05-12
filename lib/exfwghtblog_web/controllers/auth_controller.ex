defmodule ExfwghtblogWeb.AuthController do
  @moduledoc """
  Controller for logging in users
  """
  import ExfwghtblogWeb.Gettext
  use ExfwghtblogWeb, :controller


  defp map_error(:does_not_exist), do: 500
  defp map_error(:invalid_password), do: 401

  @doc """
  Logs in a user using the Guardian module
  """
  def login(conn, %{"username" => username, "password" => password}) do
    batch_id = Exfwghtblog.BatchProcessor.check_password(username, password)

    receive do
      {:batch_done, id, batch_result} when id == batch_id ->
        case batch_result.status do
          :ok ->
            token = Phoenix.Token.sign(ExfwghtblogWeb.Endpoint, "access", batch_result.user.id)

            conn
            |> put_view(json: ExfwghtblogWeb.AuthJSON)
            |> put_status(200)
            |> render("200.json", token: token)

          error ->
            code = map_error(error)

            conn
            |> put_view(json: ExfwghtblogWeb.ErrorJSON)
            |> put_status(code)
            |> render("#{code}.json", reason: error, point: :user)
        end
    after
      3000 ->
        conn
        |> put_view(json: ExfwghtblogWeb.ErrorJSON)
        |> put_status(500)
        |> render("500.json")
    end
  end
end
