defmodule ExfwghtblogWeb.RssController do
  @moduledoc """
  Controller for rendering the RSS feed
  """
  import Ecto.Query
  use ExfwghtblogWeb, :controller

  @fetch_limit 25

  def fetch(conn, _params) do
    fetch_maximum =
      max(Exfwghtblog.Repo.aggregate(Exfwghtblog.Post, :count) - @fetch_limit, @fetch_limit)

    results =
      Exfwghtblog.Repo.all(
        from p in Exfwghtblog.Post,
          order_by: [desc: p.id],
          where: p.id <= ^fetch_maximum and not p.deleted,
          limit: @fetch_limit
      )

    buildable_results = results |> Enum.map(&prepare_result/1)

    conn
    |> put_resp_content_type("application/rss+xml")
    |> send_resp(
      200,
      Exfwghtblog.RssBuilder.build_feed(
        Application.fetch_env!(:exfwghtblog, :rss_title),
        Phoenix.VerifiedRoutes.url(~p"/posts"),
        Application.fetch_env!(:exfwghtblog, :rss_description),
        buildable_results
      )
    )
  end

  defp prepare_result(%Exfwghtblog.Post{
         id: id,
         title: title,
         body: body,
         inserted_at: inserted_at
       }) do
    url = Phoenix.VerifiedRoutes.url(~p"/posts/#{id}")

    %{
      title: title,
      link: url,
      description: body,
      publication_date: inserted_at |> Exfwghtblog.RssBuilder.format_utc_to_rfc822()
    }
  end
end
