# Exfwghtblog

Elixir Featherweight Blog

## Testing Exfwghtblog

### How to register an account

```elixir
iex> Exfwghtblog.Administration.new_user(user, password)
```

Be warned that all registered accounts have posting privileges.

### Example Podman configuration

Using an environment file `.env.txt`
```
$ podman run --net=host --env-file=.env.txt CONTAINER_ID /app/bin/exfwghtblog start
```
You should use Erlang/OTP's `appup`/`relup` support instead, it will be
supported soon
