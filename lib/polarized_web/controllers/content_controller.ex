defmodule PolarizedWeb.ContentController do
  use PolarizedWeb, :controller

  alias Polarized.Content
  alias Content.Embed

  @content_server Application.get_env(:polarized, :content_server, Content.Server)

  def stream(%{req_headers: headers} = conn, %{"id" => id}) do
    id
    |> String.to_integer()
    |> @content_server.get()
    |> case do
      %Embed{} = embed ->
        Content.send_video(conn, headers, embed)

      nil ->
        send_resp(conn, 404, "")
    end
  end
end
