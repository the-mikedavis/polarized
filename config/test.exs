use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :polarized, PolarizedWeb.Endpoint,
  http: [port: 4442],
  server: false

config :polarized,
  twitter_client: ExTwitterMock,
  http_client: HTTPoisonMock,
  content_server: ContentServerMock,
  effects_client: EffectsMock

# Print only warnings and errors during test
config :logger, level: :warn
