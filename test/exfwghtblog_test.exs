defmodule ExfwghtblogTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts Exfwghtblog.Router.init([])

  doctest Exfwghtblog

  test "loads the root page"
  test "loads a blog post directory"
  test "loads a blog post file"
end
