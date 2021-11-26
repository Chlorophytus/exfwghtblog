import Config

config :logger, :console,
  format: "[$level] $message $metadata\n",
  metadata: [:conn, :path, :relative, :origin, :reason]

import_config "#{config_env()}.exs"
