defmodule PolarizedWeb.PageControllerTest do
  use PolarizedWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "polarized.tv"
  end

  test "get the credits", %{conn: conn} do
    conn = get(conn, "/credits")
    assert html_response(conn, 200) =~ "Credits"
  end
end
