defmodule Exfwghtblog.Markdown do
  # ============================================================================
  # Traversal of elements
  # ============================================================================
  # When we first traverse, reverse then perform the real traversal
  def traverse(abstract_syntax_tree) do
    abstract_syntax_tree |> traverse("")
  end

  # This is the traversal
  def traverse([element | rest_elements], html) do
    new_html =
      case element do
        # Plain text
        {tag, attributes, next, _meta} ->
          reduced_attributes =
            attributes
            |> Map.new()
            |> Enum.reduce("", &attributes/2)

          case inject_classes(tag) do
            nil ->
              "<#{tag} #{reduced_attributes}>#{traverse(next)}</#{tag}>"

            classes ->
              "<#{tag} class=\"#{classes}\" #{reduced_attributes}>#{traverse(next)}</#{tag}>"
          end

        # Rich text
        next when is_binary(next) ->
          next
      end

    traverse(rest_elements, html <> new_html)
  end

  # This is where the traversals terminate
  def traverse([], html) do
    html
  end

  # ============================================================================
  # Handle attributes
  # ============================================================================
  def attributes({key, value}, tags) do
    tags <> " #{key}=\"#{value}\""
  end

  # ============================================================================
  # Handle injecting Tailwind classes
  # ============================================================================
  def inject_classes("h1"), do: "font-bold text-xl italic"
  def inject_classes("h2"), do: "font-bold text-lg italic"
  def inject_classes("h3"), do: "font-bold text-md italic"
  def inject_classes("h4"), do: "font-bold text-md italic"
  def inject_classes("h5"), do: "font-bold text-md italic"
  def inject_classes("h6"), do: "font-bold text-md italic"
  def inject_classes("a"), do: "font-bold text-blue-800"
  def inject_classes(_other), do: nil
end
