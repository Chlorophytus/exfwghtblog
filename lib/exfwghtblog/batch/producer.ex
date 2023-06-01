defmodule Exfwghtblog.Batch.Producer do
  @moduledoc """
  Queues most database/etc. operations into a queue, eventually it goes to a
  `Batch.Consumer`
  """
  use GenStage, restart: :transient
  require Logger

  # ===========================================================================
  # Public functions
  # ===========================================================================
  @doc """
  Initializes the Producer so events can be sent
  """
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(max_demand: max_demand) do
    Logger.info("Starting Batch Producer")

    {:producer, %{queue: :queue.new()},
     dispatcher: {GenStage.DemandDispatcher, max_demand: max_demand}}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @impl true
  def handle_call({:batch_enqueue, instruction, arguments, origin_hash}, from, state) do
    event_id = :erlang.unique_integer()

    # `event_id` - lets the sender decipher event receipt order
    # `from` - what Process does this come from?
    # `instruction` - what do we do?
    # `origin_hash` - the differentiator for each client, IP address, etc.
    {:reply, event_id, [],
     %{
       state
       | queue:
           :queue.snoc(state.queue, %{
             event_id: event_id,
             from: from,
             instruction: instruction,
             arguments: arguments,
             origin_hash: origin_hash
           })
     }}
  end

  @impl true
  def handle_demand(demand, state) do
    Logger.debug("Batch Producer demand is at #{demand}")

    {queue, events} = state.queue |> pop_event(demand)
    {:noreply, events, %{state | queue: queue}}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp pop_event(queue, demand) do
    pop_event(queue, [], demand)
  end

  defp pop_event(queue, events, 0) do
    {queue, events}
  end

  defp pop_event(queue, events, demand) do
    head = :queue.head(queue)
    tail = :queue.tail(queue)
    pop_event(tail, [head | events], demand - 1)
  end
end
