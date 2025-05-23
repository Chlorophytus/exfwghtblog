defmodule ExfwghtblogWeb.Router do
  use ExfwghtblogWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ExfwghtblogWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :authenticate do
    plug ExfwghtblogWeb.Authenticate
  end

  scope "/", ExfwghtblogWeb do
    pipe_through [:browser, :authenticate]

    get "/", PageController, :home

    get "/posts/", PostControllerMulti, :show
    get "/posts/:idx", PostControllerSingle, :show
    get "/posts/:idx/edit", PostControllerEditor, :show
    get "/posts/:idx/delete", PostControllerDeleter, :show

    get "/feed", RssController, :fetch

    get "/login", LoginController, :login
    post "/logout", LoginController, :logout

    get "/publish", PublishController, :publisher
  end

  scope "/api", ExfwghtblogWeb do
    pipe_through [:api, :authenticate]

    post "/login", AuthController, :login
    post "/secure/publish", PublishController, :post
    post "/secure/publish/:idx", PublishController, :edit
    delete "/secure/publish/:idx", PublishController, :remove
  end

  # Other scopes may use custom stacks.
  # scope "/api", ExfwghtblogWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:exfwghtblog, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ExfwghtblogWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
