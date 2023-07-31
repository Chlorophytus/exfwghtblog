defmodule ExfwghtblogBackend.Administration do
  @moduledoc """
  Administration utilities
  """

  @doc """
  Generates a new user

  Be careful as all users are allowed to post blog entries
  """
  def new_user(username, password) do
    ExfwghtblogBackend.Repo.insert(%ExfwghtblogBackend.Repo.User{
      username: username,
      pass_hash: Argon2.hash_pwd_salt(password)
    })
  end

  @doc """
  Deletes a post from the general public

  Be careful as you aren't able to restore posts once they're deleted
  """
  def delete_post(id) do
    Ecto.Changeset.change(%ExfwghtblogBackend.Repo.Post{id: id}, deleted: true)
    |> ExfwghtblogBackend.Repo.update()
  end

  @doc """
  Publishes a post
  """
  def publish_post(poster, title, summary, body) do
    ExfwghtblogBackend.Repo.insert(%ExfwghtblogBackend.Repo.Post{
      poster: poster,
      title: title,
      summary: summary,
      body: body
    })
  end
end
