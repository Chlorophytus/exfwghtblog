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
    weekday =
      case Date.day_of_week(datetime) do
        1 -> "Mon"
        2 -> "Tue"
        3 -> "Wed"
        4 -> "Thu"
        5 -> "Fri"
        6 -> "Sat"
        7 -> "Sun"
      end

    month =
      case datetime.month do
        1 -> "Jan"
        2 -> "Feb"
        3 -> "Mar"
        4 -> "Apr"
        5 -> "May"
        6 -> "Jun"
        7 -> "Jul"
        8 -> "Aug"
        9 -> "Sep"
        10 -> "Oct"
        11 -> "Nov"
        12 -> "Dec"
      end

    day = datetime.day |> to_string |> String.pad_leading(2, "0")
    year = datetime.year |> to_string |> String.pad_leading(4, "0")
    hour = datetime.hour |> to_string |> String.pad_leading(2, "0")
    minute = datetime.minute |> to_string |> String.pad_leading(2, "0")
    second = datetime.second |> to_string |> String.pad_leading(2, "0")

    "#{weekday}, #{day} #{month} #{year} #{hour}:#{minute}:#{second} +0000"
  end
end
