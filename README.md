# Exfwghtblog

Elixir Featherweight Blog

## Testing Exfwghtblog

### How to register an account

```elixir
iex> Exfwghtblog.Administration.new_user(user, password)
```

Be warned that all registered accounts have posting privileges.

### Example OTP release configuration

#### Use the dev environment to release

Prepare the dependencies and release.

```shell
$ mix deps.get --only prod
$ MIX_ENV=prod mix compile
$ MIX_ENV=prod mix assets.deploy
$ MIX_ENV=prod mix release
```

#### Prepare the server

At this point our `.env` file should be made, some values will need to be replaced.

```shell
$ cat <<EOF > .env.txt
export DATABASE_URL=ecto_database_url
export SECRET_KEY_BASE=phx_secret_key
export SECRET_KEY_GUARDIAN=guardian_secret_key
export PHX_SERVER=1
export PHX_HOST=your_site
export PORT=your_port
EOF
$ source .env.txt
```

[It's best to manually create the `prod` database.](https://elixirforum.com/t/how-to-create-database-on-release/28443/2) Afterwards, migrate.

```shell
$ _build/prod/rel/exfwghtblog/bin/exfwghtblog eval "Exfwghtblog.Release.migrate"
```

Launch it, for example with `start`.

```shell
$ _build/prod/rel/exfwghtblog/bin/exfwghtblog start
```




