defmodule PolarizedWeb.SuggestionController do
  use PolarizedWeb, :controller

  alias Polarized.Repo

  def index(conn, _params) do
    {:ok, handles} = Repo.list_handles()

    suggestions = Enum.map(handles, fn %{name: name} = handle -> %{handle | id: name} end)

    render(conn, "index.html", suggestions: suggestions)
  end

  def approve(conn, _params) do
    # remove handle and add it to follower list

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def deny(conn, %{"name" => name}) do
    {:ok, ^name} = Repo.remove_handle(name)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end
end
