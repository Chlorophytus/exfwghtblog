defmodule ExfwghtblogWeb.PostHTML do
  @moduledoc """
  HTML content for the `PostController`
  """
  import Ecto.Query
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :html

  # Embed post templates here, we don't need to do anything special
  embed_templates "post_html/*"

  # Post ID is a natural number attribute
  attr :post_id, :integer

  @fetch_limit 5
  @truncation_limit 80

  # ============================================================================
  # Public functions
  # ============================================================================
  def multi_post(%{post_id: post_id} = assigns) do
    all_count = Exfwghtblog.Repo.aggregate(Exfwghtblog.Post, :count)

    assigns =
      assigns
      |> assign(:count, div(all_count, @fetch_limit))

    multi_id = all_count - post_id * @fetch_limit

    results =
      Exfwghtblog.Repo.all(
        from p in Exfwghtblog.Post,
          order_by: [desc: p.id],
          where: p.id <= ^multi_id,
          limit: @fetch_limit
      )

    results_heex =
      for result <- results do
        case result do
          %Exfwghtblog.Post{deleted: true} ->
            ~H"""
            <h2 class="font-bold text-xl"><%= gettext("Deleted") %></h2>
            """

          %Exfwghtblog.Post{
            id: id,
            title: title,
            body: body,
            inserted_at: inserted_at,
            updated_at: updated_at
          } ->
            truncated =
              if String.length(body) < @truncation_limit do
                body
              else
                "#{body |> String.slice(0..@truncation_limit) |> String.trim_trailing()}..."
              end

            assigns =
              assigns
              |> assign(:post_id, id)
              |> assign(:title, title)
              |> assign(:summary, truncated)
              |> assign(:inserted, inserted_at)
              |> assign(:updated, updated_at)

            ~H"""
            <h2 class="font-bold text-xl text-blue-800">
              <.link href={~p"/posts/#{@post_id}"}><%= @title %></.link>
            </h2>
            <p><%= @summary %></p>
            <p class="text-sm italic">
              <%= gettext("Posted %{post_date}, last update %{edit_date}",
                post_date: @inserted |> NaiveDateTime.to_string(),
                edit_date: @updated |> NaiveDateTime.to_string()
              ) %>
            </p>
            """

          _other ->
            nil
        end
      end
      |> Enum.reject(&is_nil/1)

    if length(results_heex) > 0 do
      assigns = assigns |> assign(:results, results_heex)

      ~H"""
      <%= for result <- @results do %>
        <%= result %>
        <br />
      <% end %>
      <div class="grid grid-cols-3">
        <div class="pl-48">
          <%= if @post_id > 0 do %>
            <.link href={~p"/posts?page=#{@post_id - 1}"}>
              <.icon name="hero-arrow-left-solid" class="h-6 w-6 left-0" />
            </.link>
          <% end %>
        </div>
        <div class="text-center w-full"><%= @post_id + 1 %></div>
        <div>
          <%= if @post_id < @count do %>
            <.link href={~p"/posts?page=#{@post_id + 1}"}>
              <.icon name="hero-arrow-right-solid" class="h-6 w-6 right-0" />
            </.link>
          <% end %>
        </div>
      </div>
      """
    else
      ~H"""
      <h2 class="font-bold text-xl"><%= gettext("No posts in this page currently") %></h2>
      """
    end
  end

  def single_post(%{post_id: post_id} = assigns) do
    result = Exfwghtblog.Repo.one(from p in Exfwghtblog.Post, where: p.id == ^post_id, select: p)

    case result do
      %Exfwghtblog.Post{deleted: true} ->
        ~H"""
        <h2 class="font-bold text-xl"><%= gettext("Deleted") %></h2>
        <br />
        <p class="text-sm italic"><%= gettext("This post has been deleted") %></p>
        """

      %Exfwghtblog.Post{
        body: body,
        title: title,
        inserted_at: inserted_at,
        updated_at: updated_at
      } ->
        assigns =
          assigns
          |> assign(:body, body)
          |> assign(:title, title)
          |> assign(:inserted, inserted_at)
          |> assign(:updated, updated_at)

        ~H"""
        <h2 class="font-bold text-xl"><%= @title %></h2>
        <p><%= @body %></p>
        <br />
        <p class="text-sm italic">
          <%= gettext("Posted %{post_date}, last update %{edit_date}",
            post_date: @inserted |> NaiveDateTime.to_string(),
            edit_date: @updated |> NaiveDateTime.to_string()
          ) %>
        </p>
        """

      _other ->
        ~H"""
        <h2 class="font-bold text-xl"><%= gettext("Not found") %></h2>
        <br />
        <p class="text-sm italic"><%= gettext("The post was not found") %></p>
        """
    end
  end

  def footer(assigns) do
    ~H"""
    <p class="text-center text-xs">
      Exfwghtblog v<%= Application.spec(:exfwghtblog, :vsn) %> -
      <a class="text-blue-800" href="https://github.com/Chlorophytus/exfwghtblog">
        Fork me on GitHub!
      </a>
    </p>
    """
  end
end
