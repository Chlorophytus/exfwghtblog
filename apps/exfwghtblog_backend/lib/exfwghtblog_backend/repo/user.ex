defmodule ExfwghtblogBackend.Repo.User do
  @moduledoc """
  A blog publishing user
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:pass_hash, :binary, redact: true)
    field(:username, :string)
    has_many(:posts, ExfwghtblogBackend.Repo.Post, foreign_key: :poster_id)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :pass_hash])
    |> validate_required([:username, :pass_hash])
  end
end
