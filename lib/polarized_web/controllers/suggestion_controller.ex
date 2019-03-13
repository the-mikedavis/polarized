defmodule PolarizedWeb.SuggestionController do
  use PolarizedWeb, :controller

  alias Polarized.Repo
  alias Polarized.Content.Server, as: ContentServer

  def index(conn, _params) do
    {:ok, handles} = Repo.list_handles()
    {:ok, follows} = Repo.list_follows()

    suggestions = Enum.map(handles, fn %{name: name} = handle -> %{handle | id: name} end)
    follows = Enum.map(follows, fn %{name: name} = follow -> %{follow | id: name} end)

    render(conn, "index.html", suggestions: suggestions, follows: follows)
  end

  def approve(conn, %{"name" => name}) do
    :ok = Repo.follow_handle(name)

    ContentServer.refresh()

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def deny(conn, %{"name" => name}) do
    {:ok, ^name} = Repo.remove_handle(name)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def delete(conn, %{"name" => name}) do
    :ok = Repo.unfollow_handle(name)

    conn
    |> put_flash(:info, "Successfully unfollowed #{name}.")
    |> redirect(to: Routes.suggestion_path(conn, :index))
  end
end
