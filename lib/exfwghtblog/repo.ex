defmodule Exfwghtblog.Repo do
  @moduledoc """
  PostgreSQL database
  """
  use Ecto.Repo, otp_app: :exfwghtblog, adapter: Ecto.Adapters.Postgres
end
