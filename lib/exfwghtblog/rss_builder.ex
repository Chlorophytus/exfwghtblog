defmodule Exfwghtblog.RssBuilder do
  @moduledoc """
  Uses EEx to build an RSS feed.
  """
  require EEx
  require Logger
  use GenServer

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_args) do
    {:ok, reload_generator()}
  end

  @impl true
  def handle_call(
        {:build_feed, %{title: title, link: link, description: description, items: items}},
        _from,
        %{generator: generator} = state
      ) do
    Logger.debug("RSS feed is being built")

    {result, _bindings} =
      Code.eval_quoted(generator, title: title, link: link, description: description, items: items)

    {:reply, result, state}
  end

  @impl true
  def code_change(_old_vsn, _state, _extra) do
    {:ok, reload_generator()}
  end

  # ===========================================================================
  # Public functions
  # ===========================================================================
  @doc """
  Initializes the RSS builder process
  """
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Builds the RSS feed

  See "lib/exfwghtblog/rss_builder/template.eex" for the full EEx template
  """
  def build_feed(args) do
    GenServer.call(__MODULE__, {:build_feed, args})
  end

  @doc """
  Formats a UTC `DateTime` to RFC 822 format
  """
  def format_utc_to_rfc822(datetime) do
    weekday = Date.day_of_week(datetime) |> get_day_of_week

    month = datetime.month |> get_month

    day = datetime.day |> to_string |> String.pad_leading(2, "0")
    year = datetime.year |> to_string |> String.pad_leading(4, "0")
    hour = datetime.hour |> to_string |> String.pad_leading(2, "0")
    minute = datetime.minute |> to_string |> String.pad_leading(2, "0")
    second = datetime.second |> to_string |> String.pad_leading(2, "0")

    "#{weekday}, #{day} #{month} #{year} #{hour}:#{minute}:#{second} +0000"
  end

  # ===========================================================================
  # Deprecated public functions
  # ===========================================================================
  @deprecated "Use build_feed/1 instead"
  def build_feed(title, link, description, items) do
    build_feed(%{title: title, link: link, description: description, items: items})
  end

  # ===========================================================================
  # Private functions
  #
  # NOTE: These let-it-crash when invalid data is given.
  #
  # NOTE: Also, Credo seems to like these sorts of calls instead of using case.
  # ===========================================================================
  defp reload_generator() do
    Logger.notice("RSS template is being reloaded")
    %{generator: EEx.compile_file("lib/exfwghtblog/rss_builder/template.eex")}
  end

  defp get_day_of_week(1), do: "Mon"
  defp get_day_of_week(2), do: "Tue"
  defp get_day_of_week(3), do: "Wed"
  defp get_day_of_week(4), do: "Thu"
  defp get_day_of_week(5), do: "Fri"
  defp get_day_of_week(6), do: "Sat"
  defp get_day_of_week(7), do: "Sun"

  defp get_month(1), do: "Jan"
  defp get_month(2), do: "Feb"
  defp get_month(3), do: "Mar"
  defp get_month(4), do: "Apr"
  defp get_month(5), do: "May"
  defp get_month(6), do: "Jun"
  defp get_month(7), do: "Jul"
  defp get_month(8), do: "Aug"
  defp get_month(9), do: "Sep"
  defp get_month(10), do: "Oct"
  defp get_month(11), do: "Nov"
  defp get_month(12), do: "Dec"
end
