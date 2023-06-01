defmodule Exfwghtblog.Batch.RateLimiter do
  @moduledoc """
  Rate limits `Batch.Producer` events
  """
  use GenStage, restart: :transient
  require Logger

  @doc """
  Initializes a Rate Limiter
  """
  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(args) do
    Logger.debug("Starting Batch Rate Limiter")
    {:producer_consumer, args, subscribe_to: [Exfwghtblog.Batch.Producer]}
  end

  @impl true
  def handle_events(events, _from, state) do
    Logger.debug("Determining limits for #{length(events)} events")
    utc_now = DateTime.utc_now()

    limits =
      events
      |> Enum.reduce(state.bucket_data, fn e, acc ->
        acc
        |> Map.put_new_lazy(e.origin_hash, fn -> state.rate_limits end)
        |> update_in(
          [e.origin_hash, e.instruction],
          fn limit ->
            limit |> handle_limit(get_in(state, [:default_limits, e.instruction]), utc_now)
          end
        )
      end)

    new_events =
      for event <- events do
        %{
          event_id: id,
          from: {from, _from_alias},
          origin_hash: origin_hash,
          instruction: instruction
        } = event

        # Fire the rate limiter
        origin = Exfwghtblog.Batch.get_or_start_origin(origin_hash)

        origin |> Exfwghtblog.Batch.RateStatus.hit(instruction)

        case origin |> Exfwghtblog.Batch.RateStatus.check(instruction) do
          %{remaining: 0} = rate_limit_info ->
            Logger.debug("Origin '#{origin_hash}' rate limited until #{cool_down}")
            send(from, {:rate_limited, id, rate_limit_info})

            events

          rate_limit_info ->
            [%{event | rate_limit_info: rate_limit_info} | events]
        end
      end

    {:noreply, new_events, state}
  end

  @impl true
  def code_change(_old_vsn, state, %{update_default_limits: default_limits}) do
    Logger.notice(
      "Updating rate limit defaults to #{inspect(default_limits)}, clearing previous bucket data"
    )

    {:ok, %{state | bucket_data: %{}, default_limits: default_limits}}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end
end
