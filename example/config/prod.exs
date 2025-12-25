import Config

# Production configuration
config :logger, level: :info

# Disable console colors in production
config :logger, :console, colors: [enabled: false]
