defmodule ExfwghtblogBackend.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :totp_secret, :binary
      add :pass_hash, :binary
      add :last_signin, :utc_datetime

      timestamps()
    end
  end
end
