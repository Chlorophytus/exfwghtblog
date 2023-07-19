# Main configuration
import Config

config :exfwghtblog, ecto_repos: [Exfwghtblog.Repo]

# Import "dev", "test", or "prod". Depends on environment mode.
import_config "#{config_env()}.exs"
