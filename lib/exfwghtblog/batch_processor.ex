defmodule Exfwghtblog.BatchProcessor do
  @moduledoc """
  Batches most database/etc. operations into a queue
  """
  import Ecto.Query
  use GenServer

  @multi_post_fetch_limit 5

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(args) do
    {:ok, new_state(args)}
  end

  @impl true
  def handle_call({:batch_enqueue, instruction}, from, state) do
    event_id = :erlang.unique_integer()

    {:reply, event_id,
     %{state | event_queue: :queue.snoc(state.event_queue, {event_id, from, instruction})}}
  end

  @impl true
  def handle_info(:process_timer, state) do
    :telemetry.execute(
      [:exfwghtblog, :batch_processor],
      %{congestion: :queue.len(state.event_queue)},
      %{}
    )

    if not :queue.is_empty(state.event_queue) do
      results =
        :queue.to_list(state.event_queue)
        |> Enum.map(&process_instruction/1)

      for %{task: task, from: {from, _from_alias}, event_id: id} <- results do
        send(from, {:batch_done, id, Task.await(task)})
      end
    end

    {:noreply, new_state(state.args)}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok,
     %{state | batch_timer: Process.send_after(self(), :process_timer, state.args.batch_interval)}}
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
  Enqueues a multi-post read

  Returns an ID representing the enqueued operation
  """
  def load_page(page) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:load_page, page}})
  end

  @doc """
  Enqueues a single-post read

  Returns an ID representing the enqueued operation
  """
  def load_post(idx) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:load_post, idx}})
  end

  @doc """
  Enqueues an account check

  Returns an ID representing the enqueued operation
  """
  def check_password(username, password) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:check_password, username, password}})
  end

  @doc """
  Enqueues a blog post publishing

  Returns an ID representing the enqueued operation
  """
  def publish_entry(blog_entry) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:publish_entry, blog_entry}})
  end

  @doc """
  Enqueues a blog post editing

  Returns an ID representing the enqueued operation
  """
  def try_revise_entry(requester_id, post_id, new_body) do
    GenServer.call(
      __MODULE__,
      {:batch_enqueue, {:try_revise_entry, requester_id, post_id, new_body}}
    )
  end

  @doc """
  Enqueues a blog post deletion

  Returns an ID representing the enqueued operation
  """
  def try_delete_entry(requester_id, post_id) do
    GenServer.call(__MODULE__, {:batch_enqueue, {:try_delete_entry, requester_id, post_id}})
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

  defp process_instruction({event_id, from, {:load_page, page}}) do
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
                  limit: @multi_post_fetch_limit,
                  preload: [:poster]
              )
          }
        end),
      from: from,
      event_id: event_id
    }
  end

  defp process_instruction({event_id, from, {:check_password, username, password}}) do
    user =
      Exfwghtblog.Repo.one(
        from u in Exfwghtblog.User, where: ilike(u.username, ^username), select: u
      )

    if is_nil(user) do
      %{
        task:
          Task.async(fn ->
            Argon2.no_user_verify()

            %{user: nil, status: :does_not_exist}
          end),
        from: from,
        event_id: event_id
      }
    else
      %{
        task:
          Task.async(fn ->
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

  defp process_instruction({event_id, from, {:publish_entry, blog_entry}}) do
    %{
      task:
        Task.async(fn ->
          Exfwghtblog.Repo.insert(blog_entry)
        end),
      from: from,
      event_id: event_id
    }
  end

  defp process_instruction({event_id, from, {:try_revise_entry, requester_id, post_id, new_body}}) do
    %{
      task:
        Task.async(fn ->
          results =
            Ecto.Multi.new()
            |> Ecto.Multi.one(
              :post,
              from(p in Exfwghtblog.Post,
                where: p.id == ^post_id,
                select: p,
                preload: [:poster]
              )
            )
            |> Ecto.Multi.one(:user, fn %{post: post} ->
              from(u in Exfwghtblog.User, where: u.id == ^post.poster_id, select: u)
            end)
            |> Ecto.Multi.update(:edit, fn %{post: post, user: user} ->
              if user.id == requester_id do
                Ecto.Changeset.change(post, body: new_body)
              else
                :not_your_entry
              end
            end)
            |> Exfwghtblog.Repo.transaction()

          case results do
            {:ok, %{edit: :not_your_entry} = _result} -> %{status: :not_your_entry}
            {:ok, _result} -> %{status: :ok}
            _ -> %{status: :error}
          end
        end),
      from: from,
      event_id: event_id
    }
  end

  defp process_instruction({event_id, from, {:try_delete_entry, requester_id, post_id}}) do
    %{
      task:
        Task.async(fn ->
          results =
            Ecto.Multi.new()
            |> Ecto.Multi.one(
              :post,
              from(p in Exfwghtblog.Post,
                where: p.id == ^post_id,
                select: p,
                preload: [:poster]
              )
            )
            |> Ecto.Multi.one(:user, fn %{post: post} ->
              from(u in Exfwghtblog.User, where: u.id == ^post.poster_id, select: u)
            end)
            |> Ecto.Multi.update(:edit, fn %{post: post, user: user} ->
              if user.id == requester_id do
                Ecto.Changeset.change(post, deleted: true)
              else
                :not_your_entry
              end
            end)
            |> Exfwghtblog.Repo.transaction()

          case results do
            {:ok, %{edit: :not_your_entry} = _result} -> %{status: :not_your_entry}
            {:ok, _result} -> %{status: :ok}
            _ -> %{status: :error}
          end
        end),
      from: from,
      event_id: event_id
    }
  end

  defp process_instruction({event_id, from, {:load_post, post_id}}) do
    %{
      task:
        Task.async(fn ->
          Exfwghtblog.Repo.one(
            from p in Exfwghtblog.Post, where: p.id == ^post_id, preload: [:poster]
          )
        end),
      from: from,
      event_id: event_id
    }
  end
end
