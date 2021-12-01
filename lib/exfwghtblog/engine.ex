defmodule Exfwghtblog.Engine do
  @moduledoc """
  EEx Templating Engine
  """
  require EEx

  EEx.function_from_file(
    :def,
    :post_fill,
    Application.app_dir(:exfwghtblog, Path.join(["priv", "templates", "post_fill.html.eex"])),
    [:main, :date]
  )
end
