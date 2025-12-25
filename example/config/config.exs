# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
import Config

# General application configuration
config :static_beam_example,
  env: config_env()

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config
import_config "#{config_env()}.exs"
