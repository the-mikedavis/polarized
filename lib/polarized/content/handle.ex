defmodule Polarized.Content.Handle do
  @moduledoc "A twitter handle, leans left or right"

  use Ecto.Schema

  embedded_schema do
    field :name, :string
    field :right_wing, :boolean
  end

  import Ecto.Changeset

  def changeset(user \\ %__MODULE__{}, params) do
    user
    |> cast(params, [:name, :right_wing])
    |> validate_required([:name, :right_wing])
    |> validate_length(:name, max: 15, min: 1)
    |> validate_format(:name, ~r/^\w+$/)
  end
end
