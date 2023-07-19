# Main configuration
import Config

# Import "dev", "test", or "prod". Depends on environment mode.
import_config "#{config_env()}.exs"
