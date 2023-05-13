defmodule Exfwghtblog.BatchProcessor do
  @moduledoc """
  Batches operations into a queue

  The list of operations that are batched is currently:
  - Loading multiple posts
  - Loading single posts
  - Checking passwords
  """
  require Logger
  import Ecto.Query
  use GenServer

  @send_auth_results_after 500
  @multi_post_fetch_limit 5

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(args) do
    {:ok, new_state(args)}
  end

  @impl true
  def handle_call(:check_congestion, _from, state) do
    {:reply, :queue.len(state.event_queue), state}
  end

  @impl true
  def handle_call({:batch_enqueue, instruction}, from, state) do
    event_id = :erlang.unique_integer()
    Logger.info("pushed event to batch processor server")

    {:reply, event_id,
     %{state | event_queue: :queue.snoc(state.event_queue, {event_id, from, instruction})}}
  end

  @impl true
  def handle_info(:process_timer, state) do
    if not :queue.is_empty(state.event_queue) do
      Logger.debug("batch processor server has #{:queue.len(state.event_queue)} events right now")

      :queue.to_list(state.event_queue)
      |> Enum.map(&process_instruction/1)
      |> Enum.map(&send_response/1)
    end

    {:noreply, new_state(state.args)}
  end

  # ===========================================================================
  # Public functions
  # ===========================================================================
  @doc """
  Initializes the batch processor server
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Checks the congestion of the batch queue
  """
  def get_congestion() do
    GenServer.call(__MODULE__, :check_congestion)
  end

  @doc """
  Enqueues a multi-post read

  Returns an ID representing the enqueued operation
  """
  def post_read_multi(page) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:load_multi_post, page}})
  end

  @doc """
  Enqueues a single-post read

  Returns an ID representing the enqueued operation
  """
  def post_read_single(idx) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:load_single_post, idx}})
  end

  @doc """
  Enqueues an account check

  Returns an ID representing the enqueued operation
  """
  def check_password(username, password) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:check_password, username, password}})
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp new_state(args) do
    %{
      event_queue: :queue.new(),
      batch_timer: Process.send_after(self(), :process_timer, args.batch_interval),
      args: args
    }
  end

  defp process_instruction({event_id, from, {:load_single_post, idx}}) do
    Logger.debug("load single post id #{idx}")

    result = Exfwghtblog.Repo.one(from p in Exfwghtblog.Post, where: p.id == ^idx, select: p)

    case result do
      nil ->
        %{
          task: Task.async(fn -> %{post_id: idx, status: :not_found, data: nil, poster: nil} end),
          from: from,
          event_id: event_id
        }

      %Exfwghtblog.Post{deleted: true} ->
        %{
          task: Task.async(fn -> %{post_id: idx, status: :deleted, data: nil, poster: nil} end),
          from: from,
          event_id: event_id
        }

      post ->
        poster_name =
          Exfwghtblog.Repo.one(
            from u in Exfwghtblog.User, where: u.id == ^post.poster_id, select: u.username
          )

        %{
          task:
            Task.async(fn -> %{post_id: idx, status: :ok, data: post, poster: poster_name} end),
          from: from,
          event_id: event_id
        }
    end
  end

  defp process_instruction({event_id, from, {:load_multi_post, page}}) do
    Logger.debug("load multi post page #{page}")

    %{
      task:
        Task.async(fn ->
          all_count = Exfwghtblog.Repo.aggregate(Exfwghtblog.Post, :count)

          count = div(all_count, @multi_post_fetch_limit)

          offset = all_count - page * @multi_post_fetch_limit
          %{
            page_count: count,
            page_offset: div(offset, @multi_post_fetch_limit),
            fetched:
              Exfwghtblog.Repo.all(
                from p in Exfwghtblog.Post,
                  order_by: [desc: p.id],
                  where: p.id <= ^offset,
                  limit: @multi_post_fetch_limit
              )
          }
        end),
      from: from,
      event_id: event_id
    }
  end

  defp process_instruction({event_id, from, {:check_password, username, password}}) do
    Logger.debug("check password of account '#{username}'")

    result =
      Exfwghtblog.Repo.one(
        from u in Exfwghtblog.User, where: ilike(u.username, ^username), select: u
      )

    case result do
      nil ->
        %{
          task:
            Task.async(fn ->
              Process.sleep(@send_auth_results_after)
              %{username: username, status: :does_not_exist}
            end),
          from: from,
          event_id: event_id
        }

      user ->
        %{
          task:
            Task.async(fn ->
              Process.sleep(@send_auth_results_after)

              if Argon2.verify_pass(password, user.pass_hash) do
                %{user: user, status: :ok}
              else
                %{user: user, status: :invalid_password}
              end
            end),
          from: from,
          event_id: event_id
        }
    end
  end

  defp send_response(%{task: task, from: {from, _from_alias}, event_id: id}) do
    send(from, {:batch_done, id, Task.await(task)})
  end
end
