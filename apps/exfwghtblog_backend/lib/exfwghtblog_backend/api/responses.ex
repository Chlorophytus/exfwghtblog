defmodule ExfwghtblogBackend.API.Responses do
  @moduledoc """
  Static non-error responses sent as needed

  This also contains logic for adding response times if wanted
  """

  @doc """
  Maps a term representing a response
  """
  def map_json(:health_check) do
    # In this case, return nothing
    %{e: :ok, status: :health_check}
  end

  def map_json(:version) do
    %{
      e: :ok,
      status: :version,
      version: :persistent_term.get(ExfwghtblogBackend.Version) |> to_string
    }
  end

  def map_json({:published, id}) do
    %{e: :ok, status: :published, post_id: id}
  end

  def map_json({:whoami, user}) do
    %{e: :ok, status: :whoami, username: user}
  end

  def map_json(:revised) do
    %{e: :ok, status: :revised}
  end

  def map_json(:deleted) do
    %{e: :ok, status: :deleted}
  end

  def map_json({:logged_in, token}) do
    %{e: :ok, status: :logged_in, token: token}
  end

  def map_json(:logged_out) do
    %{e: :ok, status: :logged_out}
  end

  def map_json({:page, page_count, page_data}) do
    %{e: :ok, status: :page, count: page_count, data: page_data}
  end

  def map_json({:post, post_data}) do
    %{e: :ok, status: :post, data: post_data}
  end

  def add_response_time(response, start_time) do
    milliseconds = DateTime.utc_now() |> DateTime.diff(start_time, :millisecond)

    response |> put_in(~w(latency)a, milliseconds)
  end
end
