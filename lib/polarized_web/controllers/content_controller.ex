defmodule PolarizedWeb.ContentController do
  use PolarizedWeb, :controller

  alias Polarized.Content

  def stream(%{req_headers: headers} = conn, %{"id" => id}) do
    Content.send_video(conn, headers, id)
  end
end
