defmodule Exfwghtblog.Batch.Consumer do
  @moduledoc """
  Handles events sent from a `Batch.Producer`
  """
  import Ecto.Query
  use GenStage, restart: :transient
  require Logger

  @multi_post_fetch_limit 5

  # ===========================================================================
  # Public functions
  # ===========================================================================
  @doc """
  Initializes a Consumer

  Don't name processes that are dynamically spawned
  """
  def start_link(args) do
    GenStage.start_link(__MODULE__, args)
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_args) do
    Logger.debug("Starting Batch Consumer")

    {:consumer, :the_state_does_not_matter, subscribe_to: [Exfwghtblog.Batch.RateLimiter]}
  end

  @impl true
  def handle_events(events, _from, state) do
    Logger.debug("Handling #{length(events)} events")

    results = events |> Enum.map(&process_instruction/1)

    for %{task: task, from: {from, _from_alias}, event_id: id, rate_limit_info: rate_limit_info} <-
          results do
      send(from, {:batch_done, id, rate_limit_info, Task.await(task)})
    end

    {:noreply, [], state}
  end

  @impl true
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  # NOTE: Origin Hash is only used in rate limiting stages
  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :load_page,
         arguments: {page}
       }) do
    if is_nil(page) do
      %{
        task: Task.async(fn -> :no_content end),
        from: from,
        event_id: event_id
      }
    else
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
  end

  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :load_post,
         arguments: {post_id}
       }) do
    if is_nil(post_id) do
      %{
        task: Task.async(fn -> :no_content end),
        from: from,
        event_id: event_id
      }
    else
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

  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :check_password,
         arguments: {username, password}
       }) do
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

  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :publish_entry,
         arguments: {blog_entry}
       }) do
    if is_nil(blog_entry) do
      %{
        task:
          Task.async(fn ->
            :not_logged_in
          end),
        from: from,
        event_id: event_id
      }
    else
      %{
        task:
          Task.async(fn ->
            Exfwghtblog.Repo.insert(blog_entry)
          end),
        from: from,
        event_id: event_id
      }
    end
  end

  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :try_revise_entry,
         arguments: {requester_id, post_id, new_body}
       }) do
    if is_nil(requester_id) do
      %{
        task: Task.async(fn -> %{status: :not_logged_in} end),
        from: from,
        event_id: event_id
      }
    else
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
  end

  defp process_instruction(%{
         event_id: event_id,
         from: from,
         instruction: :try_delete_entry,
         arguments: {requester_id, post_id}
       }) do
    if is_nil(requester_id) do
      %{
        task: Task.async(fn -> %{status: :not_logged_in} end),
        from: from,
        event_id: event_id
      }
    else
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
  end
end
