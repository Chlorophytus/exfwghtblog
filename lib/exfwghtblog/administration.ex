defmodule Exfwghtblog.Administration do
  @moduledoc """
  Administration utilities
  """

  @doc """
  Generates a new user. Be careful as all users are allowed to post blog
  entries.
  """
  def new_user(username, password) do
    Exfwghtblog.Repo.insert(%Exfwghtblog.Repo.User{
      username: username,
      pass_hash: Argon2.hash_pwd_salt(password)
    })
  end

  @doc """
  Deletes a post from the general public.
  """
  def delete_post(id) do
    Ecto.Changeset.change(%Exfwghtblog.Repo.Post{id: id}, deleted: true)
  end

  @doc """
  Makes a deleted post visible to the general public.
  """
  def undelete_post(id) do
    Ecto.Changeset.change(%Exfwghtblog.Repo.Post{id: id}, deleted: false)
  end
end
