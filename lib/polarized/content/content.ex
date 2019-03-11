defmodule Polarized.Content do
  @moduledoc "Content grabbing functions."

  alias __MODULE__.Handle
  alias Ecto.Changeset
  alias Polarized.Repo

  @spec change_handle(%Handle{}) :: Changeset.t()
  def change_handle(%Handle{} = handle), do: Handle.changeset(handle, %{})

  @spec create_handle(Changeset.t()) :: {:ok, %Handle{}} | {:error, :full | Changeset.t() | any()}
  def create_handle(changeset) do
    with {:ok, handle} <- Changeset.apply_action(changeset, :insert),
         :ok <- Repo.insert_handle(handle) do
      {:ok, handle}
    else
      {:error, _reason} = e -> e
    end
  end
end
