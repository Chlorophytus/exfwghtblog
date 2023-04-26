defmodule Exfwghtblog.RssBuilder do
  @moduledoc """
  Uses EEx to build an RSS feed.
  """
  require EEx

  EEx.function_from_file(:def, :build_feed, "lib/exfwghtblog/rss_builder/template.eex", [
    :title,
    :link,
    :description,
    :items
  ])

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
  # Private functions.
  #
  # NOTE: These let-it-crash when invalid data is given.
  #
  # NOTE: Also, Credo seems to like these sorts of calls instead of using case.
  # ===========================================================================
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
