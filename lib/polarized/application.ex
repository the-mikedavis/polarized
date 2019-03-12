defmodule Polarized.Application do
  @moduledoc false

  use Application

  alias Polarized.Repo
  alias Polarized.Content.Server, as: ContentServer

  def start(_type, _args) do
    children = [
      Repo,
      PolarizedWeb.Endpoint,
      ContentServer
    ]

    opts = [strategy: :one_for_one, name: Polarized.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PolarizedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
