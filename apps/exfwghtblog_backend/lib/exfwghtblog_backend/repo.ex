defmodule ExfwghtblogBackend.Repo do
  @moduledoc """
  PostgreSQL database
  """
  use Ecto.Repo, otp_app: :exfwghtblog_backend, adapter: Ecto.Adapters.Postgres
end
