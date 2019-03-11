defmodule PolarizedWeb.PageControllerTest do
  use PolarizedWeb.ConnCase, async: false

  alias Polarized.Repo
  alias Polarized.Content.Handle

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "polarized.tv"
  end

  test "get the credits", %{conn: conn} do
    conn = get(conn, "/credits")
    assert html_response(conn, 200) =~ "Credits"
  end

  test "suggesting a new user (sucessfully)", %{conn: conn} do
    params = %{"handle" => %{"name" => "a", "right_wing" => "right"}}
    conn = post(conn, "/", params)

    assert html_response(conn, 302) =~ "/"

    assert {:ok, handles} = Repo.list_handles()

    handles = Enum.map(handles, & &1.name)

    assert "a" in handles

    assert {:ok, "a"} = Repo.remove_handle("a")
  end

  test "suggesting a new user when the inbox is full", %{conn: conn} do
    handle_names = Enum.map(0..99, &to_string/1)

    inserts_valid? =
      handle_names
      |> Enum.map(fn n -> %Handle{name: n, right_wing: true} end)
      |> Enum.map(&Repo.insert_handle/1)
      |> Enum.all?(&match?(:ok, &1))

    params = %{"handle" => %{"name" => "a", "right_wing" => "right"}}
    conn = post(conn, "/", params)

    Enum.each(handle_names, &Repo.remove_handle/1)

    assert inserts_valid?

    assert html_response(conn, 302) =~ "/"
  end

  test "suggesting a user with a bad username", %{conn: conn} do
    username = "$hi$"
    params = %{"handle" => %{"name" => username, "right_wing" => "right"}}
    conn = post(conn, "/", params)

    resp = html_response(conn, 200)

    assert resp =~ username
    assert resp =~ "has invalid format"

    assert {:ok, handles} = Repo.list_handles()

    handles = Enum.map(handles, & &1.name)

    refute username in handles
  end
end
