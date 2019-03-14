defmodule PolarizedWeb.PlayerChannelTest do
  use PolarizedWeb.ChannelCase

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
end
