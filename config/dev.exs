# Development mode configuration
import Config

# Get Git commit hash. Surely there must be a better way.
config :exfwghtblog, commit_sha_result: System.cmd("git", ["symbolic-ref", "--short", "HEAD"])
