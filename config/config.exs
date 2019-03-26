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

config :polarized, Polarized.Scheduler,
  jobs: [{"@daily", {Polarized.Content.Server, :refresh, []}}]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :extwitter, :oauth,
  consumer_key: System.get_env("TWITTER_CONSUMER_KEY"),
  consumer_secret: System.get_env("TWITTER_CONSUMER_SECRET"),
  access_token: "",
  access_token_secret: ""

config :mnesia,
  dir: 'priv/data/mnesia-#{Mix.env()}'

config :polarized,
  max_tweet_count: 100

config :phoenix, :template_engines,
  slim: PhoenixSlime.Engine,
  slime: PhoenixSlime.Engine

config :duckduck,
  owner: "the-mikedavis",
  repo: "doc_gen",
  token_file: Path.join(File.cwd!(), ".goose_api_token")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
