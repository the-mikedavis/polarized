defmodule Polarized.RepoTest do
  use ExUnit.Case

  alias Polarized.Repo

  test """
  given that the Repo contains the default admin user,
  the repo leaves the record unchanged when asked to insert again.
  """ do
    user = %{username: "adminimum", password: "password"}

    assert {:ok, :unchanged} = Repo.ensure_user_inserted(user)
  end

  test """
  Given that the Repo is asked to ensure a user is inserted,
  and that user has not yet been inserted into the Repo,
  the repo inserts a new record.
  """ do
    user = %{username: "another user", password: "password"}

    resp = Repo.ensure_user_inserted(user)

    assert :ok = Repo.remove_user(user.username)

    {:ok, users} = Repo.list_users()

    assert user.username not in users

    assert resp == {:ok, :inserted}
  end
end
