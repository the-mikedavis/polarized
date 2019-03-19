defmodule PolarizedWeb.SuggestionController do
  use PolarizedWeb, :controller

  alias Polarized.Repo
  alias Polarized.Content.Server, as: ContentServer

  @content_server Application.get_env(:polarized, :content_server, ContentServer)

  def index(conn, _params) do
    {:ok, handles} = Repo.list_handles()
    {:ok, follows} = Repo.list_follows()

    suggestions = Enum.map(handles, fn %{name: name} = handle -> %{handle | id: name} end)
    follows = Enum.map(follows, fn %{name: name} = follow -> %{follow | id: name} end)

    render(conn, "index.html", suggestions: suggestions, follows: follows)
  end

  def approve(conn, params) do
    params
    |> parse_batch()
    |> Enum.each(&Repo.follow_handle/1)

    :ok = @content_server.refresh()

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def deny(conn, params) do
    params
    |> parse_batch()
    |> Enum.each(&Repo.remove_handle/1)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def delete(conn, params) do
    params
    |> parse_batch()
    |> Enum.each(&Repo.unfollow_handle/1)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  @spec parse_batch(%{String.t() => String.t()}) :: [String.t()]
  defp parse_batch(params) do
    params
    |> Map.drop(["_csrf_token", "_method", "_utf8"])
    |> Enum.filter(fn {_handle, delete?} -> delete? == "true" end)
    |> Enum.map(fn {handle, _delete?} -> handle end)
  end
end
