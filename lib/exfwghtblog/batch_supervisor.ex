defmodule Exfwghtblog.BatchSupervisor do
  @moduledoc """
  Makes sure the `BatchProcessor` restarts when it crashes
  """
  use Supervisor

  @doc """
  Starts the Batch Supervisor and its Batch Processor
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_init_arg) do
    children = [
      {Exfwghtblog.BatchProcessor,
       %{
         batch_interval: Application.get_env(:exfwghtblog, :batch_interval),
         queue_take: Application.get_env(:exfwghtblog, :queue_take)
       }}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
