defmodule PolarizedWeb.Plugs.User do
  @moduledoc false
  import Plug.Conn

  alias Polarized.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)
    user = (user_id && Accounts.user_exists?(user_id) && user_id) || nil
    assign(conn, :current_user, user)
  end
end
