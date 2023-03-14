defmodule Exfwghtblog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :deleted, :boolean, default: false
    field :summary, :string
    field :title, :string
    field :poster_id, :id

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :deleted, :summary])
    |> validate_required([:title, :body, :deleted, :summary])
  end
end
