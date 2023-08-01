# Testing mode configuration
import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :exfwghtblog_frontend, ExfwghtblogFrontend.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fzqYfAin3IHaE64qHldLpghXMyns5XUJxA13r8sGLVRR3a6P4sZZloL1ugRcSko3",
  server: false

# =============================================================================
# Backend configuration
# =============================================================================
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
  post_fetch_count: 5,
  # Don't enforce TOTP grace
  totp_enforce_time: false

config :exfwghtblog_backend, :listen_ip, {127, 0, 0, 1}
config :exfwghtblog_backend, :listen_port, 8080

# Set Guardian secret
config :exfwghtblog_backend, ExfwghtblogBackend.Guardian,
  issuer: "exfwghtblog",
  secret_key: "Pgz11xREWUK+rvlQbBYUq6yK+0jiTxTiuJX66vul+aX6zOM/Mb8jRPUahkRzqi0W"
