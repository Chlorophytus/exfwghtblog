defmodule ExfwghtblogWeb.PublishHTML do
  @moduledoc """
  HTML content for the `PublishController`
  """
  import Ecto.Query
  import ExfwghtblogWeb.Gettext

  use ExfwghtblogWeb, :html

  embed_templates "publish_html/*"
end
