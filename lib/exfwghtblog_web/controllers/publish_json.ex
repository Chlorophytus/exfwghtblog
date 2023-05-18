defmodule ExfwghtblogWeb.PublishJSON do
  @moduledoc """
  JSON templates for edit/delete API
  """

  @doc """
  Successful edit JSON
  """
  def edit_success(%{}) do
    %{
      ok: true
    }
  end

  @doc """
  Successful delete JSON
  """
  def delete_success(%{}) do
    %{
      ok: true
    }
  end
end
