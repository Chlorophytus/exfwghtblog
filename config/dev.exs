# Development mode configuration
import Config

# Get Git commit hash. Surely there must be a better way.
config :exfwghtblog_backend,
  commit_sha_result: System.cmd("git", ["rev-parse", "--short", "HEAD"])

# Configure postgres database
config :exfwghtblog_backend, ExfwghtblogBackend.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

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
  secret_key: "yusFCz/fEo8BZ6is6vgU7sN4QehQOpO5pXC/OTFZFUNoV+uacuMMdpVaSdBugif/"

# Set logger configuration
config :logger, :default_formatter,
  format: "[$date $time] [$level] $metadata$message\n",
  metadata: [:error_code, :mfa]
