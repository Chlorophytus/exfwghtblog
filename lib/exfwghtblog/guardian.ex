defmodule Exfwghtblog.Guardian do
  import Ecto.Query
  use Guardian, otp_app: :exfwghtblog

  def subject_for_token(%Exfwghtblog.User{id: id}, _claims) do
    sub = to_string(id)
    {:ok, sub}
  end

  def subject_for_token(_struct, _claims) do
    {:error, :einval}
  end

  def resource_from_claims(%{"sub" => id}) do
    resource = Exfwghtblog.Repo.one(from u in Exfwghtblog.User, where: u.id == ^id, select: u)
    {:ok, resource}
  end

  def resource_from_claims(_claims) do
    {:error, :einval}
  end
end
