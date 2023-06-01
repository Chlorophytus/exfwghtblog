defmodule Exfwghtblog.Batch.RateStatus do
  @moduledoc """
  Holds status of one `Batch.RateLimiter` origin hash
  """
  use Agent
  require Logger

  @unix_epoch ~U[1970-01-01 00:00:00Z]

  @doc """
  Initializes a rate limiting status storage agent
  """
  def start_link(_initial_value, name: name) do
    Logger.debug("Starting Batch Rate Status")

    Agent.start_link(
      fn ->
        :persistent_term.get(Exfwghtblog.Batch.RateLimits)
        |> Enum.map(fn current_limits ->
          %{current_limits | last_access: @unix_epoch, remaining: current_limits.limit, reset_const: current_limits.reset}
        end)
      end,
      name: name
    )
  end

  def check(agent, what) do
    Agent.get(agent, fn current_limits -> get_in(current_limits, [what]) end)
  end

  @doc """
  Decrements the rate limit stored in the agent

  One should call `check` afterwards to check the result
  """
  def hit(agent, what) do
    Agent.update(agent, fn current_limits ->
      now = DateTime.utc_now()
      # The seconds to wait for rate limiting to move on
      reset_const = get_in(current_limits, [what, :reset_const])

      # The amount of times the user can use this endpoint until rate limiting
      # is triggered
      limit = get_in(current_limits, [what, :limit])

      # Get time now
      # Then get the time added with the reset
      # Then subtract it with what time we last accessed
      case now |> DateTime.add(reset_const) |> DateTime.diff(get_and_update_in(current_limits, [what, :last_access], & {&1, now})) do
        time_left when time_left > 0 ->
          # Within rate limit window here
          remaining = get_in(current_limits, [what, :remaining])

          cond do
            remaining > 0 ->
              %{current_limits | reset: time_left, remaining: remaining - 1}

            true ->
              %{current_limits | reset: time_left}
          end

        _time_left ->
          # The user just reset the rate limit by waiting
          %{
            current_limits
            | remaining: limit,
            reset: reset_const
          }
      end
    end)
  end
end
