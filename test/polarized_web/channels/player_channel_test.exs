defmodule PolarizedWeb.PlayerChannelTest do
  use PolarizedWeb.ChannelCase

  alias Polarized.Content.Embed
  alias PolarizedWeb.{PlayerChannel, UserSocket}

  @content_server Application.fetch_env!(:polarized, :content_server)

  import Mox

  defp subscribe do
    {:ok, first_push, socket} =
      UserSocket
      |> socket(nil, %{})
      |> subscribe_and_join(PlayerChannel, "player:lobby")

    %{socket: socket, first_push: first_push}
  end

  setup :set_mox_global

  setup :verify_on_exit!

  setup do
    [hashtags: ~w(FNS Trade)]
  end

  test "joining the channel gives a string list of hashtags", c do
    expect(@content_server, :list_hashtags, fn -> c.hashtags end)

    %{first_push: push} = subscribe()

    assert push.hashtags == c.hashtags
  end

  test "requesting some embeds", c do
    @content_server
    |> expect(:list_hashtags, fn -> c.hashtags end)
    |> expect(:request, fn _wing, _hashes ->
      [
        %Embed{
          dest:
            "/Users/michael/cuatro/code/polarized/_build/dev/lib/polarized/priv/downloads/1104744540852883456.mp4",
          handle: %Polarized.Content.Handle{
            id: nil,
            name: "FoxNewsSunday",
            right_wing: true
          },
          hashtags: ["FNS", "Trade"],
          id: 1_104_744_540_852_883_456,
          source: "twitter",
          source_url:
            "https://video.twimg.com/amplify_video/1104739440130473986/vid/1280x720/PsGAjrYmdmhXHolU.mp4?tag=11"
        }
      ]
    end)

    %{socket: socket} = subscribe()

    ref = push(socket, "embeds", %{"wingedness" => "right", "hashtags" => ["Trade"]})

    assert_reply ref, :ok, %{
      embeds: [
        %{handle_name: "FoxNewsSunday", hashtags: ["FNS", "Trade"], id: 1_104_744_540_852_883_456}
      ]
    }
  end
end
