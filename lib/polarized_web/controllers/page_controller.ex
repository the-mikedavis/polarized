defmodule PolarizedWeb.PageController do
  use PolarizedWeb, :controller

  def index(conn, _params), do: render(conn, "index.html")

  def credits(conn, _params), do: render(conn, "credits.html")
end
