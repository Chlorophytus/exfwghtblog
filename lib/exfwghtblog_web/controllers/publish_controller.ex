defmodule ExfwghtblogWeb.PublishController do
  @moduledoc """
  Controller for publishing blog posts
  """
  use ExfwghtblogWeb, :controller

  def publish(conn, %{"title" => title, "body" => body}) do
    user = conn |> Exfwghtblog.Guardian.Plug.current_resource()

    if not is_nil(user) do
      Exfwghtblog.Repo.insert(%Exfwghtblog.Post{
        body: body,
        title: title,
        poster_id: user.id
      })

      conn |> send_resp(200, "OK")
    else
      conn |> send_resp(401, "Unauthorized")
    end
  end
end
