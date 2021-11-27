# Exfwghtblog

Elixir Featherweight Blog.

This is the backbone for chlorophyt.us as of the updating of this README.

Requires Elixir 1.12

## 502 Bad Gateway errors

Create the following files:

If it doesn't do it send me an e-mail and I'll assist you.

### In `:local` mode

- priv/res/favicon.ico
- priv/res/index.html
- priv/res/style.css

### In S3 bucket mode

- res/favicon.ico
- res/index.html
- res/style.css

## Posting

This is a featherweight system, files are alphabetically ordered if stored on S3.

If you are not storing stuff on S3, use `priv/posts` then store Markdown files.

The site by default serves files at `/posts/` and each post maps to its Markdown name without the extension.
