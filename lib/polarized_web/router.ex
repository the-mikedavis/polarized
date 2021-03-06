defmodule PolarizedWeb.Router do
  use PolarizedWeb, :router

  alias PolarizedWeb.Plugs

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug Plugs.User
  end

  pipeline :authenticate do
    plug Plugs.Auth
  end

  scope "/", PolarizedWeb do
    pipe_through :browser

    get "/", PageController, :index
    post "/suggest", SuggestionController, :suggest
    get "/stream/:id", ContentController, :stream
    get "/credits", PageController, :credits
    resources "/session", SessionController, only: [:new, :create]
    post "/session/delete", SessionController, :delete
  end

  scope "/admin", PolarizedWeb do
    pipe_through [:browser, :authenticate]

    resources "/user", UserController
    get "/suggestions", SuggestionController, :index
    put "/suggestions/approve", SuggestionController, :approve
    put "/suggestions/deny", SuggestionController, :deny
    delete "/suggestions/delete", SuggestionController, :delete
  end
end
