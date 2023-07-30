defmodule ExfwghtblogBackend.Guardian do
  @moduledoc """
  The Guardian module usage itself
  """
  import Ecto.Query
  use Guardian, otp_app: :exfwghtblog_backend

  @doc """
  Given the authentication token and the user's SQL item ID, return a subject
  """
  def subject_for_token(%{id: id}, _claims) do
    # TODO: change me into a proper authentication mechanism
    {:ok, to_string(id)}
  end

  def subject_for_token(_resource, _claims) do
    {:error, :invalid_token}
  end

  @doc """
  Given a subject, return a `ExfwghtblogBackend.Repo.User` or nothing
  """
  def resource_from_claims(%{"sub" => id}) do
    resource =
      ExfwghtblogBackend.Repo.one(
        from(u in ExfwghtblogBackend.Repo.User, where: u.id == ^id, select: u)
      )

    {:ok, resource}
  end
end
