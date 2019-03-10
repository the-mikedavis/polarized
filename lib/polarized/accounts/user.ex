defmodule Polarized.Accounts.User do
  @moduledoc """
  A user. Just a user. uname and pass.
  """

  use Ecto.Schema

  embedded_schema do
    field :username, :string
    field :password, :string
  end

  import Ecto.Changeset

  def changeset(user, params \\ %{}) do
    user
    |> cast(params, [:username, :password])
    |> validate_required([:username, :password])
    |> validate_length(:username, 4..18)
  end
end
