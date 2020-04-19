defmodule GenericWeb.Router do
  use GenericWeb, :router

  import GenericWeb.UsersAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_users
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GenericWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", GenericWeb do
  #   pipe_through :api
  # end

  scope "/" do
    pipe_through :api
    forward "/api", Absinthe.Plug, schema: GenericWeb.Schema

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: GenericWeb.Schema,
      interface: :simple
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: GenericWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", GenericWeb do
    pipe_through [:browser, :redirect_if_users_is_authenticated]

    get "/user/register", UsersRegistrationController, :new
    post "/user/register", UsersRegistrationController, :create
    get "/user/login", UsersSessionController, :new
    post "/user/login", UsersSessionController, :create
    get "/user/reset_password", UsersResetPasswordController, :new
    post "/user/reset_password", UsersResetPasswordController, :create
    get "/user/reset_password/:token", UsersResetPasswordController, :edit
    put "/user/reset_password/:token", UsersResetPasswordController, :update
  end

  scope "/", GenericWeb do
    pipe_through [:browser, :require_authenticated_users]

    delete "/user/logout", UsersSessionController, :delete
    get "/user/settings", UsersSettingsController, :edit
    put "/user/settings/update_password", UsersSettingsController, :update_password
    put "/user/settings/update_email", UsersSettingsController, :update_email
    get "/user/settings/confirm_email/:token", UsersSettingsController, :confirm_email
  end

  scope "/", GenericWeb do
    pipe_through [:browser]

    get "/user/confirm", UsersConfirmationController, :new
    post "/user/confirm", UsersConfirmationController, :create
    get "/user/confirm/:token", UsersConfirmationController, :confirm
  end
end
