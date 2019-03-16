defmodule Polarized.Content.ServerTest do
  use ExUnit.Case, async: false

  alias Polarized.Repo
  alias Polarized.Content.{Handle, Server}

  @twitter Application.fetch_env!(:polarized, :twitter_client)
  @effects Application.fetch_env!(:polarized, :effects_client)

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

    on_exit(fn ->
      :ok = Repo.unfollow_handle(handle.name)

      Server.refresh()
    end)

    [
      handle: handle,
      tweets: tweets
    ]
  end

  test "megatest muahahaha", c do
    @twitter
    |> expect(:user_timeline, fn [screen_name: _] -> c.tweets end)
    |> allow(self(), Server)

    @effects
    |> expect(:download_file, 11, fn _, dest ->
      File.cwd!()
      |> Path.join("data")
      |> File.mkdir_p!()

      [File.cwd!(), "data", "video.mp4"]
      |> Path.join()
      |> File.cp!(dest)
    end)
    |> allow(self(), Server)

    Server.refresh()

    Process.sleep(10)

    assert Server.get(5) == nil

    assert ["FNS", "Trade"] = Server.list_hashtags()

    assert [_embed] = Server.request(:_, ["Trade"])

    for embed <- Server.request(:_, ["FNS"]) do
      assert "FNS" in embed.hashtags
    end

    Process.sleep(100)
  end

  test "bad username gives empty list and no error" do
    @twitter
    |> expect(:user_timeline, fn _ ->
      raise ExTwitter.Error, message: "User does not exist!"
    end)
    |> allow(self(), Server)

    embeds = Server.fetch_state()

    assert embeds == %{}
  end
end
