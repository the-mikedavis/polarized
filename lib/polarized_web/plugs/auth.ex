defmodule PolarizedWeb.Plugs.Auth do
  @moduledoc false
  import Plug.Conn
  use PolarizedWeb, :controller

  alias Polarized.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must be signed in to access that page.")
      |> redirect(to: Routes.session_path(conn, :new))
      |> halt()
    end
  end

  @spec login(Plug.Conn.t(), String.t(), String.t()) ::
          {:ok, Plug.Conn.t()} | {:error, atom(), Plug.Conn.t()}
  def login(conn, uname, given_pass) do
    case Accounts.authenticate(uname, given_pass) do
      {:ok, %{username: uname}} ->
        {:ok, login(conn, uname)}

      {:error, :unauthorized} ->
        {:error, :unauthorized, conn}

      {:error, :not_found} ->
        {:error, :not_found, conn}
    end
  end

  def login(conn, user) do
    conn
    |> assign(:current_user, user)
    |> put_session(:user_id, user)
    |> configure_session(renew: true)
  end

  def logout(conn), do: configure_session(conn, drop: true)
end
