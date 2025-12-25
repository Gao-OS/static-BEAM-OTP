import Config

# Runtime configuration for releases
# This file is evaluated at runtime, not compile time

# You can read environment variables here:
# config :my_app, :secret_key, System.get_env("SECRET_KEY")

if config_env() == :prod do
  # Production-only runtime configuration
  # secret_key = System.get_env("SECRET_KEY") ||
  #   raise "environment variable SECRET_KEY is missing."
  #
  # config :my_app, MyApp.Endpoint,
  #   secret_key_base: secret_key
end
