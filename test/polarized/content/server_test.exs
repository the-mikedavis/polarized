defmodule Polarized.Content.ServerTest do
  use ExUnit.Case, async: false

  alias Polarized.Repo
  alias Polarized.Content.{Handle, Server}

  @http Application.fetch_env!(:polarized, :http_client)
  @twitter Application.fetch_env!(:polarized, :twitter_client)

  import Mox

  setup :verify_on_exit!

  setup do
    name = "FoxNewsSunday"
    handle = %Handle{name: name, right_wing: true}
    :ok = Repo.insert_handle(handle)
    :ok = Repo.follow_handle(handle.name)

    {tweets, _} =
      [File.cwd!(), "data", "foxnewssunday.exs"]
      |> Path.join()
      |> Code.eval_file()

    {https, _} =
      [File.cwd!(), "data", "http_reqs.exs"]
      |> Path.join()
      |> Code.eval_file()

    on_exit(fn ->
      :ok = Repo.unfollow_handle(handle.name)
      Server.refresh()
    end)

    [
      handle: handle,
      tweets: tweets,
      http_reqs: https
    ]
  end

  def get_req(url, http_reqs), do: Enum.find(http_reqs, &(&1.request.url == url))

  test "megatest muahahaha", c do
    @twitter
    |> expect(:user_timeline, fn [screen_name: _] -> c.tweets end)
    |> allow(self(), Server)

    @http
    |> expect(:get, 11, fn url ->
      {:ok, get_req(url, c.http_reqs)}
    end)
    |> allow(self(), Server)

    Server.refresh()

    Process.sleep(10)

    assert ["FNS", "Trade"] = Server.list_hashtags()

    assert [_embed] = Server.request(:_, ["Trade"])

    embeds = :sys.get_state(Server)

    assert Enum.map(embeds, & &1.hashtags) == [
             [],
             ["FNS"],
             ["FNS"],
             ["FNS"],
             ["FNS"],
             ["FNS"],
             ["FNS"],
             ["FNS", "Trade"],
             ["FNS"],
             ["FNS"],
             ["FNS"]
           ]

    for %{html: html} <- embeds do
      assert html =~ "blockquote"
    end

    for embed <- Server.request(:_, ["FNS"]) do
      assert "FNS" in embed.hashtags
    end
  end

  test "bad username gives empty list and no error" do
    @twitter
    |> expect(:user_timeline, fn _ ->
      raise ExTwitter.Error, message: "User does not exist!"
    end)
    |> allow(self(), Server)

    embeds = Server.fetch_state()

    assert embeds == []
  end
end
