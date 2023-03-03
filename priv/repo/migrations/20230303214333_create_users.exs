defmodule Exfwghtblog.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :pass_hash, :binary

      timestamps()
    end
  end
end
