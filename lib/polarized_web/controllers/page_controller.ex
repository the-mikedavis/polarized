defmodule PolarizedWeb.PageController do
  use PolarizedWeb, :controller

  alias Polarized.{Content, Content.Handle}
  alias Ecto.Changeset

  def index(conn, _params) do
    changeset = Content.change_handle(%Handle{})
    render(conn, "index.html", changeset: changeset)
  end

  def credits(conn, _params), do: render(conn, "credits.html")

  def create(conn, %{"handle" => %{"name" => name} = handle}) do
    handle
    |> translate_handle()
    |> cleanse_handle()
    |> Handle.changeset()
    |> Content.create_handle()
    |> case do
      {:ok, handle} ->
        conn
        |> put_flash(:info, "You just suggested #{handle.name}")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, :full} ->
        conn
        |> put_flash(:error, "Could not suggest #{name} because the inbox is full!")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Changeset{} = changeset} ->
        render(conn, "index.html", changeset: changeset)
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
