defmodule Exfwghtblog.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string
      add :body, :text
      add :deleted, :boolean, default: false, null: false
      add :summary, :string
      add :poster_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:posts, [:poster_id])
  end
end
