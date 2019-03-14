twitter = Application.fetch_env!(:polarized, :twitter_client)
http = Application.fetch_env!(:polarized, :http_client)
content_server = Application.fetch_env!(:polarized, :content_server)
effects = Application.fetch_env!(:polarized, :effects_client)

Mox.defmock(twitter, for: ExTwitter.Behaviour)
Mox.defmock(http, for: HTTPoison.Base)
Mox.defmock(content_server, for: Polarized.Content.Server.Behaviour)
Mox.defmock(effects, for: Polarized.Effects.Behaviour)
