defmodule Exfwghtblog.Administration do
  @moduledoc """
  Administrative utilities
  """

  @doc """
  Generates a new user. Be careful as all users are allowed to post blog
  entries.
  """
  def new_user(username, password) do
    Exfwghtblog.Repo.insert(%Exfwghtblog.User{
      username: username,
      pass_hash: Argon2.hash_pwd_salt(password)
    })
  end

  @doc """
  Hides a post from the general public.
  """
  def hide_post(id) do
    Ecto.Changeset.change(%Exfwghtblog.Post{id: id}, deleted: true)
  end

  @doc """
  Re-shows a hidden post to the general public.
  """
  def show_post(id) do
    Ecto.Changeset.change(%Exfwghtblog.Post{id: id}, deleted: false)
  end
end
