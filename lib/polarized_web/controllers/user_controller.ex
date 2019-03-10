defmodule PolarizedWeb.UserController do
  use PolarizedWeb, :controller
  use Private

  alias Polarized.{Accounts, Accounts.User}

  plug(:is_user when action in [:edit, :update, :delete])

  def index(conn, _params) do
    user = Accounts.list_users()
    render(conn, "index.html", user: user)
  end

  def new(conn, _params) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user)
        |> assign(:current_user, user)
        |> put_flash(:info, "Success. You're now logged in as #{user}")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, _params) do
    user = conn.assigns.user
    changeset = Accounts.change_user(%User{username: user})
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}) do
    user = conn.assigns.user

    case Accounts.update_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.page_path(conn, :index))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, _params) do
    user = conn.assigns.user
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.user_path(conn, :index))
  end

  private do
    # allow passage if and only if this user is the user they're trying to
    # access.
    @spec is_user(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    defp is_user(conn, _opts) do
      id = String.to_integer(conn.params["id"])

      # we can use the dot notation because this is run after the authentication
      # plug
      if id && conn.assigns.current_user == id do
        assign(conn, :user, id)
      else
        conn
        |> put_flash(:error, "You cannot modify a different user.")
        |> redirect(to: Routes.user_path(conn, :index))
        |> halt()
      end
    end
  end
end
