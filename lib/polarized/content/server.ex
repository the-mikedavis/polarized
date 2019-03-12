defmodule Polarized.Content.Server do
  use GenServer
  use Private

  alias Polarized.Content.Embed

  @moduledoc """
  A Server that collects videos from users and serves that video.
  """

  def start_link(_opts \\ []), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  def init(nil) do
    {:ok, fetch_state()}
  end

  def refresh, do: GenServer.cast(__MODULE__, :refresh)

  def handle_cast(:refresh, _state), do: {:noreply, fetch_state()}

  private do
    alias Polarized.Repo

    @spec fetch_state() :: [%Embed{}]
    defp fetch_state do
      {:ok, follows} = Repo.list_follows()

      follows
      |> Enum.map(& &1.name)
      |> Embed.fetch()
    end
  end
end
