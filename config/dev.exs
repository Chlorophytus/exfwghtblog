# Development mode configuration
import Config

# Get Git commit hash. Surely there must be a better way.
config :exfwghtblog_backend,
  commit_sha_result: System.cmd("git", ["symbolic-ref", "--short", "HEAD"])

# Set time-to-live
config :exfwghtblog_backend, session_ttl_minutes: 15

# Configure postgres database
config :exfwghtblog_backend, ExfwghtblogBackend.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# Set Guardian secret
config :exfwghtblog_backend, ExfwghtblogBackend.Guardian,
  issuer: "exfwghtblog",
  secret_key: "yusFCz/fEo8BZ6is6vgU7sN4QehQOpO5pXC/OTFZFUNoV+uacuMMdpVaSdBugif/"
