defmodule PolarizedWeb.PlayerChannelTest do
  use PolarizedWeb.ChannelCase

  alias PolarizedWeb.{PlayerChannel, UserSocket}

  setup do
    {:ok, first_push, socket} =
      UserSocket
      |> socket(nil, %{})
      |> subscribe_and_join(PlayerChannel, "player:lobby")

    [socket: socket, first_push: first_push]
  end

  test "joining the channel gives a string list of hashtags", c do
    assert c.first_push == %{hashtags: []}
  end
end
