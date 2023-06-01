defmodule Exfwghtblog.Batch do
  @moduledoc """
  Database/etc calls and supervisor

  SEE:
  - `Batch.Producer`
  - `Batch.RateLimiter`
  - `Batch.Consumer`
  """
  use Supervisor

  # ===========================================================================
  # Public functions
  # ===========================================================================
  @doc """
  Hashes the origin IP address, whether it be IPv4 or IPv6
  """
  def origin_hash({_a, _b, _c, _d} = ipv4) do
    origin_hash(:inet.ipv4_mapped_ipv6_address(ipv4))
  end

  def origin_hash({a, b, c, d, e, f, g, h}) do
    <<ipv6::big-unsigned-unit(16)-size(8)>> =
      <<a::16, b::16, c::16, d::16, e::16, f::16, g::16, h::16>>

    :crypto.hash(:sha3_256, ipv6)
    |> Base.url_encode64()
  end

  @doc """
  Starts the Batch Supervisor and its Batch Processor
  """
  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Enqueues a multi-post read

  Returns an ID representing the enqueued operation
  """
  def load_page(page, origin_hash) do
    GenStage.call(__MODULE__.Producer, {:batch_enqueue, {:load_page, page}, origin_hash})
  end

  @doc """
  Enqueues a single-post read

  Returns an ID representing the enqueued operation
  """
  def load_post(idx, origin_hash) do
    GenStage.call(__MODULE__.Producer, {:batch_enqueue, :load_post, {idx}, origin_hash})
  end

  @doc """
  Enqueues an account check

  Returns an ID representing the enqueued operation
  """
  def check_password(username, password, origin_hash) do
    GenStage.call(
      __MODULE__.Producer,
      {:batch_enqueue, :check_password, {username, password}, origin_hash}
    )
  end

  @doc """
  Enqueues a blog post publishing

  Returns an ID representing the enqueued operation
  """
  def publish_entry(blog_entry, origin_hash) do
    GenStage.call(
      __MODULE__.Producer,
      {:batch_enqueue, :publish_entry, {blog_entry}, origin_hash}
    )
  end

  @doc """
  Enqueues a blog post editing

  Returns an ID representing the enqueued operation
  """
  def try_revise_entry(requester_id, post_id, new_body, origin_hash) do
    GenStage.call(
      __MODULE__.Producer,
      {:batch_enqueue, :try_revise_entry, {requester_id, post_id, new_body}, origin_hash}
    )
  end

  @doc """
  Enqueues a blog post deletion

  Returns an ID representing the enqueued operation
  """
  def try_delete_entry(requester_id, post_id, origin_hash) do
    GenStage.call(
      __MODULE__.Producer,
      {:batch_enqueue, :try_delete_entry, {requester_id, post_id}, origin_hash}
    )
  end

  @doc """
  Gets or starts a `Batch.RateStatus` associated with the specified origin hash
  """
  def get_or_start_origin(origin_hash) do
    case Registry.lookup(Exfwghtblog.Batch.Registry, origin_hash) do
      [{_, process}] -> process
      [] ->
        {:ok, process} = __MODULE__.RateStatusSupervisor.start_child()
        {:ok, ^process} = Registry.register(__MODULE__.Registry, origin_hash, process)
        process
    end
  end
  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(max_demand: max_demand, rate_limiting?: false) do
    :persistent_term.put(__MODULE__.RateLimits, %{
      load_post: %{limit: 10, reset: 1},
      load_page: %{limit: 10, reset: 1},
      check_password: %{limit: 2, reset: 60},
      publish_entry: %{limit: 1, reset: 10},
      try_delete_entry: %{limit: 1, reset: 10},
      try_revise_entry: %{limit: 1, reset: 10}
    })

    children = [
      {Exfwghtblog.Batch.Producer, max_demand: max_demand},
      Exfwghtblog.Batch.RateLimiter,
      Exfwghtblog.Batch.Consumer,
      {Registry, keys: :unique, name: Exfwghtblog.Batch.Registry},
      Exfwghtblog.Batch.RateStatusSupervisor
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
