defmodule PolarizedWeb.SuggestionControllerTest do
  use PolarizedWeb.ConnCase, async: false

  alias Polarized.Content.Handle
  alias Polarized.Repo

  import Mox

  @content_server Application.fetch_env!(:polarized, :content_server)

  setup :verify_on_exit!

  setup :as_admin

  describe "suggestions" do
    setup do
      username = "apple"
      record = %Handle{name: username, right_wing: false, id: username}

      :ok = Repo.insert_handle(record)

      on_exit(fn ->
        {:ok, ^username} = Repo.remove_handle(username)
      end)

      [
        username: username,
        record: record
      ]
    end

    test "getting all suggestions", %{conn: conn, username: username} do
      conn = get(conn, Routes.suggestion_path(conn, :index))
      assert html_response(conn, 200) =~ username
    end

    test "denying a suggestion", %{conn: conn, username: username} do
      params = %{username => "true"}
      conn = put(conn, Routes.suggestion_path(conn, :deny), params)
      assert html_response(conn, 302) =~ "/admin/suggestions"
    end

    test "approving a suggestion", %{conn: conn, username: username} do
      expect(@content_server, :add, fn _ -> :ok end)

      params = %{username => "true"}
      conn = put(conn, Routes.suggestion_path(conn, :approve), params)
      assert html_response(conn, 302) =~ "/admin/suggestions"

      {:ok, follows} = Repo.list_follows()

      assert username in Enum.map(follows, & &1.name)

      assert :ok = Repo.unfollow_handle(username)

      assert {:ok, []} = Repo.list_follows()

      {:ok, handles} = Repo.list_handles()

      refute username in Enum.map(handles, & &1.name)
    end
  end

  describe "follows" do
    setup do
      username = "apple"
      record = %Handle{name: username, right_wing: false, id: username}

      :ok = Repo.insert_handle(record)
      :ok = Repo.follow_handle(username)

      on_exit(fn -> :ok = Repo.unfollow_handle(username) end)

      [
        username: username,
        record: record
      ]
    end

    test "deleting a follower", c do
      expect(@content_server, :remove, fn _ -> :ok end)

      params = %{c.username => "true"}
      conn = delete(c.conn, Routes.suggestion_path(c.conn, :delete), params)
      assert html_response(conn, 302) =~ "/admin/suggestions"

      {:ok, follows} = Repo.list_follows()

      refute c.username in Enum.map(follows, & &1.name)
    end
  end
end
