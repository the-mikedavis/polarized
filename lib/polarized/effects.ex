defmodule Polarized.Effects do
  @moduledoc "Things that are hard to mox"

  use Private

  require Logger

  alias __MODULE__.Behaviour
  @behaviour Behaviour

  alias Polarized.Repo

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
      case :hackney.stream_body(client) do
        {:ok, data} ->
          {[data], {client, size + byte_size(data)}}

        :done ->
          {:halt, {client, size}}
      end
    end

    @spec finish_download({reference(), integer()}) :: :ok
    defp finish_download({_client, _size}), do: :ok
  end

  def setup_tables(tables) do
    for {table_name, attributes} <- tables do
      table_name
      |> :mnesia.create_table(attributes: attributes, disc_copies: [node()])
      |> case do
        {:atomic, :ok} ->
          Logger.info("#{table_name} table created with attributes #{inspect(attributes)}.")

        {:aborted, {:already_exists, ^table_name}} ->
          :ok

        {:aborted, reason} ->
          Logger.error("Could not create #{table_name} table. Reason: #{inspect(reason)}")
      end
    end
  end

  def seed do
    {:ok, users} = Repo.list_users_impl()

    if users == [] do
      %{username: "adminimum", password: "pleasechangethis"}
      |> Repo.ensure_user_inserted_impl()
      |> case do
        {:ok, :inserted} ->
          Logger.info("Admin user added.")

          # wait for changes to mnesia to propagate to disk
          Process.sleep(2_000)

        {:error, reason} ->
          Logger.error("Insertion failed! #{inspect(reason)}")
      end
    else
      Logger.debug("Admin user was already inserted.")
    end

    :ok
  end
end
