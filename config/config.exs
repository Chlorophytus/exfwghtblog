# Main configuration
import Config

config :exfwghtblog_backend, ecto_repos: [ExfwghtblogBackend.Repo]

# Import "dev", "test", or "prod". Depends on environment mode.
import_config "#{config_env()}.exs"
