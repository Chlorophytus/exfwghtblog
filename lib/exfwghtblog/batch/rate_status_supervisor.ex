defmodule Exfwghtblog.Batch.RateStatusSupervisor do
  @moduledoc """
  Dynamically supervises `Batch.RateStatus` agents
  """
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child() do
    DynamicSupervisor.start_child(__MODULE__, {Exfwghtblog.Batch.RateStatus, []})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
