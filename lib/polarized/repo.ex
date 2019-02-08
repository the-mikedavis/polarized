defmodule Polarized.Repo do
  use Ecto.Repo,
    otp_app: :polarized,
    adapter: Ecto.Adapters.Postgres
end
