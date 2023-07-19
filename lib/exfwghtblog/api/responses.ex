defmodule Exfwghtblog.API.Responses do
  @moduledoc """
  Static non-error responses sent as needed

  This also contains logic for adding response times if wanted
  """

  @doc """
  Maps a term representing a response
  """
  def map_json(:health_check) do
    # In this case, return nothing
    %{e: :ok}
  end
  def map_json(:version) do
    %{e: :ok, version: :persistent_term.get(Exfwghtblog.Version) |> to_string}
  end


  def add_response_time(response, start_time) do
    milliseconds = DateTime.utc_now() |> DateTime.diff(start_time, :millisecond)

    response |> put_in(~w(latency)a, milliseconds)
  end
end
