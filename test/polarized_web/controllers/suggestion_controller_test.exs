defmodule PolarizedWeb.SuggestionControllerTest do
  use PolarizedWeb.ConnCase, async: false

  alias Polarized.Content.Handle
  alias Polarized.Repo

  import Mox

  @content_server Application.fetch_env!(:polarized, :content_server)

  setup :verify_on_exit!

  setup :as_admin

  describe "follows" do
    setup do
      username = "apple"
      record = %Handle{name: username, right_wing: false, id: username}

      :ok = Repo.follow_handle(record)

      on_exit(fn -> :ok = Repo.unfollow_handle(username) end)

      [
        username: username,
        record: record
      ]
    end

    test "listing followers", c do
      conn = get(c.conn, Routes.suggestion_path(c.conn, :index))
      assert html_response(conn, 200) =~ c.username
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

  describe "suggesting" do
    test "suggesting a new user (sucessfully)", %{conn: conn} do
      params = %{"handle" => %{"name" => "a", "right_wing" => "right"}}
      conn = post(conn, Routes.suggestion_path(conn, :suggest), params)

      assert html_response(conn, 302) =~ "/"

      assert {:ok, handles} = Repo.list_follows()

      handles = Enum.map(handles, & &1.name)

      assert "a" in handles

      assert :ok = Repo.unfollow_handle("a")
    end

    test "suggesting a user with a bad username", %{conn: conn} do
      username = "$hi$"
      params = %{"handle" => %{"name" => username, "right_wing" => "right"}}
      conn = post(conn, Routes.suggestion_path(conn, :suggest), params)

      resp = html_response(conn, 200)

      assert resp =~ username
      assert resp =~ "has invalid format"

      assert {:ok, handles} = Repo.list_follows()

      handles = Enum.map(handles, & &1.name)

      refute username in handles
    end
  end
end
