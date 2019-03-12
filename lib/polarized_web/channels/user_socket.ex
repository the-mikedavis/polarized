defmodule PolarizedWeb.UserSocket do
  use Phoenix.Socket

  channel "player:*", PolarizedWeb.PlayerChannel

  # all sockets are allowed without authentication because it's all user facing
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # all sockets are anonymous because they're read only
  def id(_socket), do: nil
end
