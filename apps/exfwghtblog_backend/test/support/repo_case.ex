defmodule ExfwghtblogBackend.RepoCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias ExfwghtblogBackend.Repo

      import Ecto
      import Ecto.Query
      import ExfwghtblogBackend.RepoCase

      # and any other stuff
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(ExfwghtblogBackend.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(ExfwghtblogBackend.Repo, {:shared, self()})
    end

    :ok
  end
end
