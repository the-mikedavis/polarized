defmodule Polarized.Content do
  @moduledoc "Content grabbing functions."

  use Private

  @effects Application.get_env(:polarized, :effects_client, :effects)

  alias __MODULE__.{Embed, Handle}
  alias Ecto.Changeset
  alias Polarized.Repo

  @spec change_handle(%Handle{}) :: Changeset.t()
  def change_handle(%Handle{} = handle), do: Handle.changeset(handle, %{})

  @spec create_handle(Changeset.t()) :: {:ok, %Handle{}} | {:error, :full | Changeset.t() | any()}
  def create_handle(changeset) do
    with {:ok, handle} <- Changeset.apply_action(changeset, :insert),
         :ok <- Repo.insert_handle(handle) do
      {:ok, handle}
    else
      {:error, _reason} = e -> e
    end
  end

  @spec download_dir() :: Path.t()
  def download_dir, do: Path.join("#{:code.priv_dir(:polarized)}", "downloads")

  @spec download_path(%Embed{}) :: Path.t()
  def download_path(%Embed{id: id}), do: Path.join(download_dir(), "#{id}.mp4")

  @spec download_embed(%Embed{}) :: %Embed{}
  def download_embed(%Embed{source_url: url} = embed) do
    dest = download_path(embed)

    unless File.exists?(dest), do: :ok = @effects.download_file(url, dest)

    %Embed{embed | dest: dest}
  end

  @doc """
  Send a video out of a socket.
  """
  @spec send_video(Plug.Conn.t(), Keyword.t(), %Embed{}) :: Plug.Conn.t()
  def send_video(conn, headers, embed) do
    video_path = embed.dest
    offset = get_offset(headers)
    file_size = get_file_size(video_path)

    conn
    |> Plug.Conn.put_resp_header("content-type", "video/mp4")
    |> Plug.Conn.put_resp_header(
      "content-range",
      "bytes #{offset}-#{file_size - 1}/#{file_size}"
    )
    |> Plug.Conn.send_file(206, video_path, offset, file_size - offset)
  end

  private do
    @spec get_offset(Keyword.t()) :: non_neg_integer()
    defp get_offset(headers) do
      case List.keyfind(headers, "range", 0) do
        {"range", "bytes=" <> start_pos} ->
          start_pos
          |> String.split("-")
          |> List.first()
          |> String.to_integer()

        _ ->
          0
      end
    end

    @spec get_file_size(Path.t()) :: non_neg_integer()
    defp get_file_size(path) do
      %{size: size} = File.stat!(path)

      size
    end
  end
end
