defmodule Polarized.Accounts do
  @moduledoc """
  Helper functions for dealing with accounts (users)
  """

  alias Polarized.Repo
  alias __MODULE__.User
  alias Comeonin.Argon2, as: Crypto
  alias Ecto.Changeset

  @spec change_user(%User{}) :: Ecto.Changeset.t()
  def change_user(%User{} = user \\ %User{}), do: User.changeset(user, %{})

  @spec list_users() :: [String.t()]
  def list_users do
    {:ok, users} = Repo.list_users()

    users
  end

  @spec create_user(%{username: String.t(), password: String.t()}) ::
          {:ok, String.t()} | {:error, Changeset.t() | any()}
  def create_user(user_map) do
    changeset = User.changeset(%User{}, user_map)

    with {:ok, user} <- Changeset.apply_action(changeset, :insert),
         {:ok, user} <- Repo.insert_user(user) do
      {:ok, user}
    else
      {:error, :exists} ->
        {:error, Changeset.add_error(changeset, :username, "User already exists")}

      e ->
        e
    end
  end

  @spec update_user(%{username: String.t(), password: String.t()}) ::
          {:ok, String.t()} | {:error, Changeset.t() | any()}
  def update_user(user_map) do
    changeset = User.changeset(%User{}, user_map)

    with {:ok, user} <- Changeset.apply_action(changeset, :update),
         {:ok, user} <- Repo.upsert_user(user) do
      {:ok, user}
    else
      e -> e
    end
  end

  @spec delete_user(String.t()) :: {:ok, String.t()} | {:error, any()}
  def delete_user(uname) do
    case Repo.remove_user(uname) do
      :ok -> {:ok, uname}
      e -> e
    end
  end

  @spec user_exists?(String.t()) :: boolean()
  def user_exists?(username), do: {:ok, true} == Repo.user_exists?(username)

  @spec authenticate(String.t(), String.t()) :: {:ok, %User{}} | {:error, atom()}
  def authenticate(username, given_password) do
    {:ok, user} = Repo.get_user(username)

    cond do
      user && Crypto.checkpw(given_password, user.hashed_password) ->
        {:ok, user}

      user ->
        {:error, :unauthorized}

      true ->
        Crypto.dummy_checkpw()

        {:error, :not_found}
    end
  end
end
