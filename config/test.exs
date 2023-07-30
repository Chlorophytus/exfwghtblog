# Testing mode configuration
import Config

# Configure postgres database
config :exfwghtblog_backend, ExfwghtblogBackend.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_test",
  pool: Ecto.Adapters.SQL.Sandbox

# Set sesion time-to-live low
config :exfwghtblog_backend, session_ttl_minutes: 5

# Set Guardian secret
config :exfwghtblog_backend, ExfwghtblogBackend.Guardian,
  issuer: "exfwghtblog",
  secret_key: "Pgz11xREWUK+rvlQbBYUq6yK+0jiTxTiuJX66vul+aX6zOM/Mb8jRPUahkRzqi0W"
