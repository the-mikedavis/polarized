defmodule Polarized.Content.ServerTest do
  use ExUnit.Case, async: false

  alias Polarized.Repo
  alias Polarized.Content.{Handle, Server}

  @twitter Application.fetch_env!(:polarized, :twitter_client)
  @http Application.fetch_env!(:polarized, :http_client)

  import Mox

  setup :verify_on_exit!

  setup do
    handle = %Handle{name: "FoxNewsSunday", right_wing: true}
    :ok = Repo.insert_handle(handle)
    :ok = Repo.follow_handle(handle.name)

    on_exit(fn -> :ok = Repo.unfollow_handle(handle.name) end)

    {tweets, _} =
      [File.cwd!(), "data", "foxnewssunday.exs"]
      |> Path.join()
      |> Code.eval_file()

    {https, _} =
      [File.cwd!(), "data", "http_reqs.exs"]
      |> Path.join()
      |> Code.eval_file()

    [
      handle: handle,
      tweets: tweets,
      http_reqs: https
    ]
  end

  # YARD this makes me sad...
  test "mega test muahahahaha", %{handle: %{name: name}} = c do
    @twitter
    |> expect(:user_timeline, fn [screen_name: ^name] -> c.tweets end)
    |> allow(self(), Server)

    @http
    |> expect(:get, 11, fn url ->
      assert url =~ "publish.twitter.com/oembed"

      {:ok, get_req(url, c.http_reqs)}
    end)
    |> allow(self(), Server)

    Server.refresh()

    Process.sleep(10)

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

    assert [_embed] = Server.request(:_, ["Trade"])
  end

  defp get_req(url, http_reqs), do: Enum.find(http_reqs, &(&1.request.url == url))

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
