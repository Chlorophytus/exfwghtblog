defmodule Exfwghtblog.AwsAgent do
  @moduledoc """
  Holds onto the AWS client structure. Call `get` to get the client itself.
  """
  use Agent

  def start_link([]) do
    idx = Application.fetch_env!(:exfwghtblog, :bucket_idx)
    key = Application.fetch_env!(:exfwghtblog, :bucket_key)
    loc = Application.fetch_env!(:exfwghtblog, :bucket_loc)
    Agent.start_link(fn -> AWS.Client.create(idx, key, loc) end, name: __MODULE__)
  end

  @doc """
  Returns the AWS client.
  """
  def get do
    Agent.get(__MODULE__, & &1)
  end
end
