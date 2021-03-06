defmodule Polarized.Content.Embed do
  @moduledoc """
  An embedded video or GIF.
  """

  use Private

  @twitter Application.get_env(:polarized, :twitter_client, ExTwitter)
  @tweet_count Application.fetch_env!(:polarized, :max_tweet_count)

  defstruct source: nil,
            source_url: nil,
            hashtags: [],
            handle: nil,
            id: nil,
            dest: nil,
            text: nil,
            link: nil

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
        |> Enum.filter(&tweet_embeds_video?/1)
        |> Enum.map(&parse_tweet(&1, user))

      {:error, _reason} ->
        []
    end
  end

  private do
    @spec pull_recent_tweets(Handle.t()) :: {:ok, [%Tweet{}]} | {:error, any()}
    defp pull_recent_tweets(%Handle{name: username}) do
      try do
        {:ok, @twitter.user_timeline(screen_name: username, count: @tweet_count)}
      rescue
        e -> {:error, e}
      end
    end

    # YARD include youtube embeds (links)
    @spec tweet_embeds_video?(%Tweet{}) :: boolean()
    defp tweet_embeds_video?(%Tweet{extended_entities: entities}) do
      with media when is_list(media) <- entities[:media] do
        Enum.any?(media, &(&1.type == "video"))
      else
        # no media
        nil -> false
      end
    end

    @spec parse_tweet(%Tweet{}, %Handle{}) :: %__MODULE__{}
    defp parse_tweet(
           %Tweet{
             id_str: id,
             entities: %{hashtags: hashtags},
             user: %{profile_image_url: prof_url},
             text: text
           } = tweet,
           %Handle{} = handle
         ) do
      hashtags = Enum.map(hashtags, & &1.text)

      {source, source_url} = parse_source(tweet)

      [text, link_id | _] = String.split(text, "https://t.co/")

      text = String.trim_trailing(text)

      link = "https://t.co/" <> link_id

      %__MODULE__{
        id: id,
        handle: %Handle{handle | profile_picture_url: prof_url},
        source: source,
        source_url: source_url,
        hashtags: hashtags,
        text: text,
        link: link
      }
    end

    @spec parse_source(%Tweet{}) :: {String.t(), String.t()}
    defp parse_source(%Tweet{extended_entities: %{media: media}}) do
      %{video_info: %{variants: available}} =
        media
        |> Enum.filter(&(&1.type == "video"))
        |> List.first()

      source_url =
        available
        |> Enum.filter(&(&1.content_type == "video/mp4"))
        |> Enum.sort_by(& &1.bitrate)
        |> List.last()
        |> Map.fetch!(:url)

      {"twitter", source_url}
    end
  end
end
