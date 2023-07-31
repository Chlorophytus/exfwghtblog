# Main configuration
import Config

config :exfwghtblog_frontend,
  ecto_repos: [],
  generators: [context_app: false]

# Configures the endpoint
config :exfwghtblog_frontend, ExfwghtblogFrontend.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: ExfwghtblogFrontend.ErrorHTML, json: ExfwghtblogFrontend.ErrorJSON],
    layout: false
  ],
  pubsub_server: ExfwghtblogFrontend.PubSub,
  live_view: [signing_salt: "Oh4Q7JWv"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/exfwghtblog_frontend/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.3.2",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../apps/exfwghtblog_frontend/assets", __DIR__)
  ]

# =============================================================================
# Backend configuration
# =============================================================================
config :exfwghtblog_backend, ecto_repos: [ExfwghtblogBackend.Repo]
# Import "dev", "test", or "prod". Depends on environment mode.
import_config "#{config_env()}.exs"
