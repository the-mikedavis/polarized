defmodule PolarizedWeb.SessionControllerTest do
  use PolarizedWeb.ConnCase

  test "GET / of session", %{conn: conn} do
    conn = get(conn, Routes.session_path(conn, :new))
    assert html_response(conn, 200) =~ "Log in"
  end

  setup do
    [username: "adminimum", password: "pleasechangethis"]
  end

  test "logging in to adminimum brings you to user listing", %{conn: conn, username: uname, password: pass} do
    params = %{"session" => %{"username" => uname, "password" => pass}}
    conn = post(conn, Routes.session_path(conn, :create), params)
    assert html_response(conn, 302) =~ "/admin/user"
  end

  test "bad pass gives you an error", %{conn: conn, password: pass} do
    params = %{"session" => %{"username" => "hi", "password" => pass}} 
    conn = post(conn, Routes.session_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Invalid username/password combination"
  end

  test "bad username gives you an error", %{conn: conn, username: uname} do
    params = %{"session" => %{"username" => uname, "password" => "password"}}
    conn = post(conn, Routes.session_path(conn, :create), params)
    assert html_response(conn, 200) =~ "Invalid username/password combination"
  end

  test "logging out of adminimum", %{conn: conn, username: uname} do
    conn =
      conn
      |> Plug.Test.init_test_session(%{user_id: uname})
      |> assign(:current_user, uname)
      |> post(Routes.session_path(conn, :delete), %{})

    assert html_response(conn, 302) =~ "/"
  end
end
