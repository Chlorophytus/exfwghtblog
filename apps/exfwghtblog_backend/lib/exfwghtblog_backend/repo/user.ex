defmodule ExfwghtblogBackend.Repo.User do
  @moduledoc """
  A blog publishing user
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:pass_hash, :binary, redact: true)
    field(:totp_secret, :binary, redact: true)
    field(:last_signin, :utc_datetime)
    field(:username, :string)
    has_many(:posts, ExfwghtblogBackend.Repo.Post, foreign_key: :poster_id)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :pass_hash, :totp_secret, :last_signin])
    |> validate_required([:username, :pass_hash, :totp_secret, :last_signin])
  end
end
