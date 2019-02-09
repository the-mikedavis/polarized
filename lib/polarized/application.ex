defmodule Polarized.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Polarized.Repo,
      PolarizedWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Polarized.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    PolarizedWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
