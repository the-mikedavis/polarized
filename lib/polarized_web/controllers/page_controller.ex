defmodule PolarizedWeb.PageController do
  use PolarizedWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
