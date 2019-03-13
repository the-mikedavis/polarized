defmodule PolarizedWeb.PlayerChannel do
  use PolarizedWeb, :channel

  alias Polarized.Content.Server, as: ContentServer

  @moduledoc """
  The channel used to communicate with the outside users.

  Sends them embeds.
  """

  def join("player:lobby", _params, socket) do
    {:ok, %{hashtags: ContentServer.list_hashtags()}, socket}
  end
end
