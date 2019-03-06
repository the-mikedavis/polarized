use Mix.Config

config :polarized, PolarizedWeb.Endpoint,
  http: [:inet6, port: "${POLARIZED_PORT}"],
  url: [host: "${POLARIZED_HOST}"],
  secret_key_base: "${POLARIZED_SECRET_KEYBASE}",
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true

config :logger, level: :info
