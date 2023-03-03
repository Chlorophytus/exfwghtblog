# Exfwghtblog

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Testing Exfwghtblog

### How to register an account

```elixir
iex> Exfwghtblog.Administration.new_user(user, password)
```

### How to log in

```sh
$ curl -X POST -H "Content-Type: application/json" -d '{"username":"user","password":"password"}' -c /tmp/exfwghtblog_cookies.txt localhost:4000/login
```

### How to post

Cookies or HTTP `Authentication` header may be used.

```sh
$ curl -X POST -H "Content-Type: application/json" -d '{"title":"test","body":"test blog entry 2"}' -b /tmp/exfwghtblog_cookies.txt localhost:4000/secure/publish
```
