defmodule Polarized.Content.Embed do
  @moduledoc """
  An embedded video or GIF.
  """

  @twitter Application.get_env(:polarized, :twitter_client, ExTwitter)
  @http Application.get_env(:polarized, :http_client, HTTPoison)

  defstruct html: nil, hashtags: [], handle: nil, id: nil

  alias Polarized.Content.Handle
  alias ExTwitter.Model.Tweet

  @spec fetch(Handle.t() | [Handle.t()]) :: [%__MODULE__{}]
  def fetch(users) when is_list(users) do
    users
    |> Enum.map(&fetch/1)
    |> List.flatten()
  end

  def fetch(%Handle{} = user) do
    case pull_recent_tweets(user) do
      {:ok, tweets} ->
        tweets
        |> Enum.map(fn t -> {t, user} end)
        |> Enum.filter(&tweet_embeds_video?/1)
        |> Enum.map(&tweet_with_url/1)
        |> Enum.map(&to_struct/1)
        |> Enum.reject(&is_nil/1)

      {:error, _reason} ->
        []
    end
  end

  @doc "Returns a list of tweets for this username"
  @spec pull_recent_tweets(Handle.t()) :: {:ok, [%Tweet{}]} | {:error, any()}
  def pull_recent_tweets(%Handle{name: username}) do
    try do
      {:ok, @twitter.user_timeline(screen_name: username)}
    rescue
      e in ExTwitter.Error -> {:error, e}
    end
  end

  # YARD include youtube embeds (links)
  @spec tweet_embeds_video?({%Tweet{}, Handle.t()}) :: boolean()
  def tweet_embeds_video?({%Tweet{extended_entities: entities}, _handle}) do
    with media when is_list(media) <- entities[:media] do
      Enum.any?(media, &(&1.type == "video"))
    else
      # no media
      nil -> false
    end
  end

  @spec tweet_with_url({%Tweet{}, Handle.t()}) :: {%Tweet{}, String.t(), Handle.t()}
  def tweet_with_url({%Tweet{id_str: id} = tweet, %Handle{name: name} = handle}) do
    url =
      "https://publish.twitter.com/oembed?dnt=true&url=" <>
        "https%3A%2F%2Ftwitter.com%2F#{name}%2Fstatus%2F#{id}"

    {tweet, url, handle}
  end

  @spec to_struct({%Tweet{}, String.t(), Handle.t()}) :: %__MODULE__{}
  def to_struct({%Tweet{entities: %{hashtags: hashtags}, id: id}, url, handle}) do
    hashtags = Enum.map(hashtags, & &1.text)

    case @http.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        embed_html =
          body
          |> Jason.decode!()
          |> Map.fetch!("html")

        %__MODULE__{html: embed_html, hashtags: hashtags, handle: handle, id: id}

      {:error, _reason} ->
        nil
    end
  end
end
