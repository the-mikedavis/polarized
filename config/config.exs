# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :polarized, PolarizedWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "a76GaFcnniGepgbY2Vjv3h4/AdtZBvnOsa6JgYcI5GCwumtgTe73jrC8xAvcOxY/",
  render_errors: [view: PolarizedWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Polarized.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :extwitter, :oauth,
  consumer_key: "",
  consumer_secret: "",
  access_token: "",
  access_token_secret: ""

config :mnesia,
  dir: 'priv/data/mnesia-#{Mix.env()}'

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
