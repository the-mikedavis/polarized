defmodule PolarizedWeb.SessionController do
  use PolarizedWeb, :controller

  alias PolarizedWeb.Plugs.Auth

  def new(conn, _), do: render(conn, "new.html")

  def create(conn, %{"session" => %{"username" => u, "password" => p}}) do
    case Auth.login(conn, u, p) do
      {:ok, conn} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> redirect(to: Routes.user_path(conn, :index))

      {:error, _reason, conn} ->
        conn
        |> put_flash(:error, "Invalid username/password combination")
        |> render("new.html")
    end
  end

  def delete(conn, _) do
    conn
    |> Auth.logout()
    |> redirect(to: Routes.page_path(conn, :index))
  end
end
