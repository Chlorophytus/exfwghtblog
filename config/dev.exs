# Development mode configuration
import Config

# Get Git commit hash. Surely there must be a better way.
config :exfwghtblog, commit_sha_result: System.cmd("git", ["symbolic-ref", "--short", "HEAD"])

# Configure postgres database
config :exfwghtblog, Exfwghtblog.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
