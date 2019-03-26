defmodule PolarizedWeb.SuggestionController do
  use PolarizedWeb, :controller

  alias Polarized.Repo
  alias Polarized.Content
  alias Content.Handle
  alias Content.Server, as: ContentServer
  alias Ecto.Changeset

  @content_server Application.get_env(:polarized, :content_server, ContentServer)

  def index(conn, _params) do
    {:ok, handles} = Repo.list_handles()
    {:ok, follows} = Repo.list_follows()

    suggestions = Enum.map(handles, fn %{name: name} = handle -> %{handle | id: name} end)
    follows = Enum.map(follows, fn %{name: name} = follow -> %{follow | id: name} end)
    changeset = Content.change_handle(%Handle{})

    render(conn, "index.html", suggestions: suggestions, follows: follows, changeset: changeset)
  end

  def approve(conn, params) do
    names = parse_batch(params)

    Enum.each(names, &Repo.follow_handle/1)

    Enum.each(names, &@content_server.add/1)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def deny(conn, params) do
    params
    |> parse_batch()
    |> Enum.each(&Repo.remove_handle/1)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  def delete(conn, params) do
    names = parse_batch(params)

    Enum.each(names, &Repo.unfollow_handle/1)

    Enum.each(names, &@content_server.remove/1)

    redirect(conn, to: Routes.suggestion_path(conn, :index))
  end

  @spec parse_batch(%{String.t() => String.t()}) :: [String.t()]
  defp parse_batch(params) do
    params
    |> Map.drop(["_csrf_token", "_method", "_utf8"])
    |> Enum.filter(fn {_handle, delete?} -> delete? == "true" end)
    |> Enum.map(fn {handle, _delete?} -> handle end)
  end

  def suggest(conn, %{"handle" => %{"name" => name} = handle}) do
    handle
    |> translate_handle()
    |> cleanse_handle()
    |> Handle.changeset()
    |> Content.create_handle()
    |> case do
      {:ok, handle} ->
        conn
        |> put_flash(:info, "You suggested #{handle.name}")
        |> redirect(to: Routes.suggestion_path(conn, :index))

      {:error, :full} ->
        conn
        |> put_flash(:error, "Could not suggest #{name} because the inbox is full!")
        |> redirect(to: Routes.suggestion_path(conn, :index))

      {:error, %Changeset{} = changeset} ->
        {:ok, handles} = Repo.list_handles()
        {:ok, follows} = Repo.list_follows()

        suggestions = Enum.map(handles, fn %{name: name} = handle -> %{handle | id: name} end)
        follows = Enum.map(follows, fn %{name: name} = follow -> %{follow | id: name} end)

        render(conn, "index.html",
          changeset: changeset,
          suggestions: suggestions,
          follows: follows
        )
    end
  end

  defp translate_handle(%{"name" => _name, "right_wing" => wing_string} = handle) do
    wingedness =
      case wing_string do
        "left" -> false
        "right" -> true
        _ -> nil
      end

    %{handle | "right_wing" => wingedness}
  end

  defp cleanse_handle(%{"name" => name} = handle) do
    name =
      name
      |> String.replace("@", "")
      |> String.trim()

    %{handle | "name" => name}
  end
end
