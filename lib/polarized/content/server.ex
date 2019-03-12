defmodule Polarized.Content.Server do
  use GenServer
  use Private

  alias Polarized.Content.{Embed, Handle}

  @moduledoc """
  A Server that collects videos from users and serves that video.
  """

  ## public-ish stuff

  @spec request(:_ | boolean(), :_ | [String.t()]) :: [%Embed{}]
  def request(right_wing?, hashtags),
    do: GenServer.call(__MODULE__, {:request, right_wing?, hashtags})

  ## private-ish stuff

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl GenServer
  def init(nil), do: {:ok, fetch_state()}

  def refresh, do: GenServer.cast(__MODULE__, :refresh)

  @impl GenServer
  def handle_call({:request, right_wing?, hashtags}, _from, state) do
    embeds =
      state
      |> Enum.filter(&match_left_right(right_wing?, &1))
      |> Enum.filter(&match_hashtags(hashtags, &1))

    {:reply, embeds, state}
  end

  @impl GenServer
  def handle_cast(:refresh, _state), do: {:noreply, fetch_state()}

  @impl GenServer
  def handle_info(:refresh, _state), do: {:noreply, fetch_state()}

  private do
    alias Polarized.Repo

    @spec fetch_state() :: [%Embed{}]
    defp fetch_state do
      case Repo.list_follows() do
        {:ok, follows} ->
          Embed.fetch(follows)

        {:error, _reason} ->
          Process.send_after(self(), :refresh, 200)

          []
      end
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
