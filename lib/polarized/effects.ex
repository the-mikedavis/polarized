defmodule Polarized.Effects do
  @moduledoc "Things that are hard to mox"

  use Private

  alias __MODULE__.Behaviour
  @behaviour Behaviour

  @impl Behaviour
  def download_file(url, dest) do
    file = File.stream!(dest, [:write, :binary])

    :ok =
      fn -> begin_download(url) end
      |> Stream.resource(&continue_download/1, &finish_download/1)
      |> Stream.into(file)
      |> Stream.run()
  end

  private do
    @spec begin_download(String.t()) :: {reference(), integer()}
    defp begin_download(url) do
      {:ok, _status, _headers, client} = :hackney.get(url, [], "", [])

      {client, 0}
    end

    @spec continue_download({reference(), integer()}) ::
            {[binary()] | :halt, {reference(), integer()}}
    defp continue_download({client, size}) do
      case :hackney.stream_body({client, size}) do
        {:ok, data} ->
          {[data], {client, size + byte_size(data)}}

        :done ->
          {:halt, {client, size}}
      end
    end

    @spec finish_download({reference(), integer()}) :: :ok
    defp finish_download({_client, _size}), do: :ok
  end
end
