defmodule PolarizedWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias PolarizedWeb.Router.Helpers, as: Routes
      import PolarizedWeb.ConnCase

      # The default endpoint for testing
      @endpoint PolarizedWeb.Endpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  import Plug.Test, only: [init_test_session: 2]
  alias Polarized.Repo

  def as_admin(context) do
    username = Map.get(context, :username, "a user")
    password = Map.get(context, :password, "password")
    conn = Map.get(context, :conn, Phoenix.ConnTest.build_conn())

    {:ok, _} = Repo.insert_user(%{username: username, password: password})

    on_exit(fn -> :ok = Repo.remove_user(username) end)

    [username: username, password: password, conn: init_test_session(conn, user_id: username)]
  end
end
