defmodule PolarizedWeb.SuggestionControllerTest do
  use PolarizedWeb.ConnCase, async: false

  alias Polarized.Content.Handle
  alias Polarized.Repo

  import Plug.Test, only: [init_test_session: 2]

  setup %{conn: conn} do
    username = "apple"
    record = %Handle{name: username, right_wing: false, id: username}

    :ok = Repo.insert_handle(record)

    on_exit(fn ->
      {:ok, ^username} = Repo.remove_handle(username)
    end)

    [
      username: username,
      record: record,
      conn: init_test_session(conn, user_id: "adminimum")
    ]
  end

  test "getting all suggestions", %{conn: conn, username: username} do
    conn = get(conn, Routes.suggestion_path(conn, :index))
    assert html_response(conn, 200) =~ username
  end

  test "denying a suggestion", %{conn: conn, username: username} = c do
    params = %{"name" => username}
    conn = put(conn, Routes.suggestion_path(conn, :deny, c.record), params)
    assert html_response(conn, 302) =~ "/admin/suggestions"
  end
end
