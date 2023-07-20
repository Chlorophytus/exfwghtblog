# Testing mode configuration
import Config

# Configure postgres database
config :exfwghtblog_backend, ExfwghtblogBackend.Repo,
  username: "postgres",
  password: "change_me",
  hostname: "127.0.0.1",
  database: "exfwghtblog_test",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10
