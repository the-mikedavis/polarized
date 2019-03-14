defmodule PolarizedWeb.PlayerChannel do
  use PolarizedWeb, :channel

  alias Polarized.Content.Server, as: ContentServer

  @content_server Application.get_env(:polarized, :content_server, ContentServer)

  @moduledoc """
  The channel used to communicate with the outside users.

  Sends them embeds.
  """

  def join("player:lobby", _params, socket) do
    {:ok, %{hashtags: @content_server.list_hashtags()}, socket}
  end
end
