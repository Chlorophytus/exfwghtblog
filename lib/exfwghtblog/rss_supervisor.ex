defmodule Exfwghtblog.RssSupervisor do
  @moduledoc """
  Makes sure the `RssBuilder` restarts when it crashes
  """
  use Supervisor

  @doc """
  Starts the RSS Supervisor and its GenServer
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
      {Exfwghtblog.RssBuilder, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
