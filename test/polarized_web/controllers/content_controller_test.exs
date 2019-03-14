defmodule PolarizedWeb.ContentControllerTest do
  use PolarizedWeb.ConnCase

  alias Polarized.Content.Embed

  @content_server Application.fetch_env!(:polarized, :content_server)

  import Mox

  setup :verify_on_exit!

  setup do
    embed = %Embed{
      id: 113_654_156,
      dest: Path.join([File.cwd!(), "data", "video.mp4"])
    }

    [embed: embed]
  end

  # YARD this is awkward to fake http requests about videos
  # it'd be nice to have some html-based thing like wallaby / hound for these
  # things
  test "getting a video", %{conn: conn} = c do
    expect(@content_server, :get, fn _id -> c.embed end)

    conn = get(conn, Routes.content_path(conn, :stream, c.embed))

    assert <<0, 0, 0, 28, 102, 116, 121>> <> _rest = conn.resp_body
    assert {"content-type", "video/mp4"} in conn.resp_headers
    assert conn.status == 206
  end

  test "the video does not exist", %{conn: conn} = c do
    expect(@content_server, :get, fn _id -> nil end)

    conn = get(conn, Routes.content_path(conn, :stream, c.embed))

    assert conn.status == 404
  end
end
