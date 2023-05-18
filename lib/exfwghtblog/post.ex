defmodule Exfwghtblog.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :deleted, :boolean, default: false
    field :summary, :string
    field :title, :string
    belongs_to :poster, Exfwghtblog.User

    timestamps()
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :deleted, :summary, :title])
    |> validate_required([:body, :deleted, :summary, :title])
  end
end
