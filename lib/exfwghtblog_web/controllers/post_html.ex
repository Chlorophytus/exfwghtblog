defmodule ExfwghtblogWeb.PostHTML do
  @moduledoc """
  HTML content for the `PostController`
  """
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :html

  # Embed post templates here, we don't need to do anything special
  embed_templates "post_html/*"

  attr :batch_result, :any
  attr :user_id, :integer

  @truncation_limit 80
  # ===========================================================================
  # Show multiple posts
  # ===========================================================================
  def multi_post(%{batch_result: batch_result} = assigns) do
    assigns =
      assigns
      |> assign(count: batch_result.page_count)
      |> assign(offset: batch_result.page_offset)

    results_heex =
      for result <- batch_result.fetched do
        case result do
          %Exfwghtblog.Post{deleted: true} ->
            ~H"""
            <div class="bg-slate-100 p-6 shadow-md">
              <h2 class="font-bold text-xl">{gettext("Deleted")}</h2>
            </div>
            """

          %Exfwghtblog.Post{
            id: id,
            title: title,
            summary: summary,
            inserted_at: inserted_at,
            updated_at: updated_at,
            poster: poster
          } ->
            truncated =
              if String.length(summary) < @truncation_limit do
                summary
              else
                "#{summary |> String.slice(0..@truncation_limit) |> String.trim_trailing()}..."
              end

            assigns =
              assigns
              |> assign(:post_id, id)
              |> assign(:title, title)
              |> assign(:summary, truncated)
              |> assign(:inserted, inserted_at)
              |> assign(:updated, updated_at)
              |> assign(:name, poster.username)

            ~H"""
            <div class="bg-slate-100 p-6 shadow-md">
              <h2 class="font-bold text-xl">
                <.link class="text-blue-800" href={~p"/posts/#{@post_id}"}>{@title}</.link>
              </h2>
              <p>{@summary}</p>
              <p class="text-sm italic">
                {gettext("Posted by %{username} on %{post_date}, last update %{edit_date}",
                  username: @name,
                  post_date: @inserted |> NaiveDateTime.to_iso8601(),
                  edit_date: @updated |> NaiveDateTime.to_iso8601()
                )}
              </p>
            </div>
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
        {result}
        <br />
      <% end %>
      <div class="grid grid-cols-3">
        <div class="pl-48">
          <%= if @offset > 0 do %>
            <.link href={~p"/posts?page=#{@offset - 1}"}>
              <.icon name="hero-arrow-left-solid" class="h-6 w-6 left-0" />
            </.link>
          <% end %>
        </div>
        <div class="text-center w-full">{@offset + 1}</div>
        <div>
          <%= if @offset < (@count - 1) do %>
            <.link href={~p"/posts?page=#{@offset + 1}"}>
              <.icon name="hero-arrow-right-solid" class="h-6 w-6 right-0" />
            </.link>
          <% end %>
        </div>
      </div>
      """
    else
      ~H"""
      <h2 class="font-bold text-xl">{gettext("No posts in this page currently")}</h2>
      """
    end
  end

  # ===========================================================================
  # Show single posts
  # ===========================================================================
  def single_post(
        %{
          batch_result: %Exfwghtblog.Post{
            id: id,
            summary: summary,
            body: body,
            title: title,
            inserted_at: inserted_at,
            updated_at: updated_at,
            poster: poster
          },
          user_id: user_id
        } = assigns
      ) do
    # Need to make line breaks \r\n style to HTML...
    {:ok, markdown_ast, _errors} = body |> EarmarkParser.as_ast()

    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:summary, summary)
      |> assign(:body, markdown_ast |> Exfwghtblog.Markdown.traverse())
      |> assign(:title, title)
      |> assign(:inserted, inserted_at)
      |> assign(:updated, updated_at)
      |> assign(:name, poster.username)
      |> assign(:can_edit, user_id == poster.id)

    ~H"""
    <div class="bg-slate-100 p-6 shadow-md">
      <%= if @can_edit do %>
        <span class="float-right">
          <.link href={~p"/posts/#{@id}/edit"}>
            <.icon name="hero-pencil-solid" />
          </.link>
          <.link href={~p"/posts/#{@id}/delete"}>
            <.icon name="hero-trash-solid" />
          </.link>
        </span>
      <% end %>
      <h2 class="font-bold text-xl">{@title}</h2>
      <p>{@summary}</p>
      <br />
      <p>{raw(@body)}</p>
      <br />
      <p class="text-sm italic">
        {gettext("Posted by %{username} at %{post_date}, last update %{edit_date}",
          username: @name,
          post_date: @inserted |> NaiveDateTime.to_iso8601(),
          edit_date: @updated |> NaiveDateTime.to_iso8601()
        )}
      </p>
    </div>
    """
  end

  # ===========================================================================
  # Edit single posts
  # ===========================================================================
  def single_edit(
        %{
          batch_result: %Exfwghtblog.Post{
            id: id,
            summary: summary,
            body: body,
            title: title
          }
        } = assigns
      ) do
    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:summary, summary)
      |> assign(:body, body)
      |> assign(:title, title)

    ~H"""
    <div class="bg-slate-100 p-6 shadow-md">
      <form
        data-idx={@id}
        id="edit-form"
        action={~p"/api/secure/publish/#{@id}"}
        class="w-full m-auto"
      >
        <h2 class="font-bold text-xl">{@title} <i>(editing)</i></h2>
        <p>{@summary}</p>
        <br />
        <textarea
          id="edit-body"
          rows="8"
          cols="80"
          name="body"
          class="rounded-md p-3 m-1 w-full bg-gray-200 shadow-md"
        ><%= @body %></textarea>
        <br />
        <input
          type="submit"
          value="Edit"
          class="bg-yellow-100 hover:bg-yellow-200 rounded-full p-3 m-1 w-full shadow-md"
        />
      </form>
    </div>
    """
  end

  # ===========================================================================
  # Delete single posts
  # ===========================================================================
  def single_delete(
        %{
          batch_result: %Exfwghtblog.Post{
            id: id,
            summary: summary,
            title: title
          }
        } = assigns
      ) do
    assigns =
      assigns
      |> assign(:id, id)
      |> assign(:summary, summary)
      |> assign(:title, title)

    ~H"""
    <div class="bg-slate-100 p-6 shadow-md">
      <h2 class="font-bold text-xl">{@title} <i>(deletion)</i></h2>
      <p>{@summary}</p>
      <br />
      <form data-idx={@id} id="delete-form" method="post" class="w-full m-auto">
        <input
          type="submit"
          value="Delete"
          class="bg-red-100 hover:bg-red-200 rounded-full p-3 m-1 w-full shadow-md"
        />
      </form>
    </div>
    """
  end
end
