defmodule PolarizedWeb.PlayerChannel do
  use PolarizedWeb, :channel

  alias Polarized.Content.Embed
  alias Polarized.Content.Server, as: ContentServer

  @content_server Application.get_env(:polarized, :content_server, ContentServer)

  @moduledoc """
  The channel used to communicate with the outside users.

  Sends them embeds.
  """

  def join("player:lobby", _params, socket) do
    {:ok, %{hashtags: @content_server.list_hashtags()}, socket}
  end

  def handle_in("embeds", %{"wingedness" => wingedness, "hashtags" => hashtags}, socket) do
    embeds =
      wingedness
      |> to_query()
      |> @content_server.request(hashtags)
      |> Enum.map(&embed_to_map/1)
      |> Enum.shuffle()

    {:reply, {:ok, %{embeds: embeds}}, socket}
  end

  @spec to_query(String.t()) :: :_ | boolean()
  defp to_query(wingedness) do
    case wingedness do
      "left" -> false
      "right" -> true
      "both" -> :_
    end
  end

  @spec embed_to_map(%Embed{}) :: map()
  defp embed_to_map(%Embed{handle: %{name: name, profile_picture_url: prof}} = embed) do
    embed
    |> Map.take([:hashtags, :id])
    |> Map.put(:handle_name, name)
    |> Map.put(:profile_picture_url, prof)
  end
end
