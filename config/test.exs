# Testing mode configuration
import Config

# Configure postgres database
config :exfwghtblog_backend, ExfwghtblogBackend.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_test",
  pool: Ecto.Adapters.SQL.Sandbox

# Set attributes
config :exfwghtblog_backend,
  # Login time-to-live is 5 minutes
  session_ttl_minutes: 5,
  # Blog titles are up to 80 characters
  title_limit: 80,
  # Blog summaries are up to 250 characters
  summary_limit: 250,
  # Blog bodies are up to 5000 characters
  body_limit: 5000,
  # Limit pages to 5 posts
  post_fetch_count: 5

# Set Guardian secret
config :exfwghtblog_backend, ExfwghtblogBackend.Guardian,
  issuer: "exfwghtblog",
  secret_key: "Pgz11xREWUK+rvlQbBYUq6yK+0jiTxTiuJX66vul+aX6zOM/Mb8jRPUahkRzqi0W"
