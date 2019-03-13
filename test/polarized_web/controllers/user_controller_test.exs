defmodule PolarizedWeb.UserControllerTest do
  use PolarizedWeb.ConnCase, async: false

  alias Polarized.Repo

  describe "un-logged in access is redirected to /session/new" do
    test "GET /", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      assert html_response(conn, 302) =~ "/session/new"
    end
  end

  describe "logged in access" do
    setup :as_admin

    test "listing users", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :index))
      resp = html_response(conn, 200)

      assert resp =~ "Admins"
      assert resp =~ "adminimum"
    end

    test "new user page", %{conn: conn} do
      conn = get(conn, Routes.user_path(conn, :new))
      resp = html_response(conn, 200)

      assert resp =~ "Username"
      assert resp =~ "**********"
    end

    test "creating a new user (success)", %{conn: conn} = c do
      uname = "another user"

      params = %{"user" => %{"username" => uname, "password" => c.password}}
      conn = post(conn, Routes.user_path(conn, :create), params)

      assert html_response(conn, 302) =~ "/"

      {:ok, users} = Repo.list_users()
      assert uname in users

      assert :ok = Repo.remove_user(uname)
    end

    test "creating a new user when that user already exists", %{conn: conn} = c do
      params = %{"user" => %{"username" => "adminimum", "password" => c.password}}
      conn = post(conn, Routes.user_path(conn, :create), params)

      assert html_response(conn, 200) =~ "User could not be created"
    end

    test "trying to edit a different user fails", %{conn: conn} do
      conn = get(conn, "/admin/user/another_user/edit")
      assert html_response(conn, 302) =~ "/admin/user"
    end
  end

  describe "operations with one's own self" do
    setup :as_admin

    test "getting the edit page", %{conn: conn} = c do
      conn = get(conn, "/admin/user/#{c.username}/edit")
      resp = html_response(conn, 200)

      assert resp =~ "edit"
      assert resp =~ c.username
    end

    test "updating password", %{conn: conn} = c do
      params = %{"user" => %{"username" => c.username, "password" => "otherpass"}}
      conn = put(conn, "/admin/user/#{c.username}", params)

      assert html_response(conn, 302) =~ "/"
    end

    test "bad username edit", %{conn: conn} = c do
      params = %{"user" => %{"username" => "eve", "password" => c.password}}
      conn = put(conn, "/admin/user/#{c.username}", params)

      assert html_response(conn, 200) =~ "edit"
    end

    test "deleting yourself", %{conn: conn} = c do
      conn = delete(conn, "/admin/user/#{c.username}", %{})

      assert html_response(conn, 302) =~ "/admin/user"
    end
  end
end
