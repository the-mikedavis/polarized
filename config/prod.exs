use Mix.Config

config :polarized, PolarizedWeb.Endpoint,
  http: [:inet6, port: "${POLARIZED_PORT}"],
  url: [host: "${POLARIZED_HOST}"],
  secret_key_base: "${POLARIZED_SECRET_KEYBASE}",
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :extwitter, :oauth,
  consumer_key: "${TWITTER_CONSUMER_KEY}",
  consumer_secret: "${TWITTER_CONSUMER_SECRET}",

config :logger, level: :info
