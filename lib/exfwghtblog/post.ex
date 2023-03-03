defmodule Exfwghtblog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :deleted, :boolean, default: false
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:title, :body, :deleted])
    |> validate_required([:title, :body, :deleted])
  end
end
