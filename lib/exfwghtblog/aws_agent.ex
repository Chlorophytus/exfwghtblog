defmodule Exfwghtblog.AwsAgent do
  @moduledoc """
  Holds onto the AWS client structure. Call `get` to get the client itself.
  """
  use Agent

  def start_link([]) do
    unless is_nil(System.get_env("S3BUCKET")) do
      idx = System.get_env("S3BUCKET_IDX")
      key = System.get_env("S3BUCKET_KEY")
      loc = System.get_env("S3BUCKET_LOC")
      Agent.start_link(fn -> AWS.Client.create(idx, key, loc) end, name: __MODULE__)
    else
      Agent.start_link(fn -> :local end, name: __MODULE__)
    end
  end

  @doc """
  Returns the AWS client.
  """
  def get do
    Agent.get(__MODULE__, & &1)
  end
end
