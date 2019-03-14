defmodule Polarized.Content.Server do
  use GenServer
  use Private

  alias Polarized.Content
  alias Content.{Embed, Handle}
  alias __MODULE__.Behaviour

  @behaviour Behaviour

  # embed id => %Embed{}
  @typep state :: %{integer() => %Embed{}}

  @moduledoc """
  A Server that collects videos from users and serves that video.
  """

  ## public-ish stuff

  @doc "Retreives a set of embeds that match a request"
  @impl Behaviour
  def request(right_wing?, hashtags),
    do: GenServer.call(__MODULE__, {:request, right_wing?, hashtags})

  @impl Behaviour
  def list_hashtags, do: GenServer.call(__MODULE__, :hashtags)

  @impl Behaviour
  def get(id), do: GenServer.call(__MODULE__, {:get, id})

  ## private-ish stuff

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl GenServer
  def init(nil), do: {:ok, fetch_state()}

  def refresh, do: GenServer.cast(__MODULE__, :refresh)

  def enrich(embed), do: GenServer.cast(__MODULE__, {:enrich, embed})

  @impl GenServer
  def handle_call({:request, right_wing?, hashtags}, _from, state) do
    embeds =
      state
      |> Enum.map(fn {_id, embed} -> embed end)
      |> Enum.filter(&match_left_right(right_wing?, &1))
      |> Enum.filter(&match_hashtags(hashtags, &1))

    {:reply, embeds, state}
  end

  def handle_call(:hashtags, _from, state) do
    hashtags =
      state
      |> Enum.reduce([], fn {_id, embed}, acc -> embed.hashtags ++ acc end)
      |> Enum.uniq()

    {:reply, hashtags, state}
  end

  def handle_call({:get, id}, _from, state), do: {:reply, Map.get(state, id), state}

  @impl GenServer
  def handle_cast({:enrich, embed}, state) do
    embed = Content.download_embed(embed)

    {:noreply, Map.put(state, embed.id, embed)}
  end

  def handle_cast(:refresh, state), do: {:noreply, fetch_state(state)}

  @impl GenServer
  def handle_info(:refresh, state), do: {:noreply, fetch_state(state)}

  private do
    alias Polarized.Repo

    @spec fetch_state() :: state()
    defp fetch_state do
      case Repo.list_follows() do
        {:ok, follows} ->
          state =
            follows
            |> Embed.fetch()
            |> Enum.reduce(%{}, fn embed, acc -> Map.put(acc, embed.id, embed) end)

          for {_id, embed} <- state, do: enrich(embed)

          state

        {:error, _reason} ->
          Process.send_after(self(), :refresh, 200)

          []
      end
    end

    @spec fetch_state(state()) :: state()
    defp fetch_state(prior_state) do
      for {_id, embed} <- prior_state do
        :ok = File.rm!(embed.dest)
      end

      fetch_state()
    end

    @spec match_left_right(:_ | boolean(), %Embed{}) :: boolean()
    # match all
    def match_left_right(:_, _), do: true
    # match the boolean
    def match_left_right(lr?, %Embed{handle: %Handle{right_wing: lr?}}), do: true
    # clashing booleans
    def match_left_right(_, _), do: false

    @spec match_hashtags(:_ | [String.t()], %Embed{}) :: boolean()
    # match all
    def match_hashtags(:_, _), do: true
    # match if any of the wants are in the haves
    def match_hashtags(wants, %Embed{hashtags: haves}), do: Enum.any?(wants, &(&1 in haves))
  end
end
