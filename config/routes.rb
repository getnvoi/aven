Aven::Engine.routes.draw do
  # Logout route
  get(:logout, to: "auth#logout", as: :logout)

  # OAuth routes
  namespace :oauth do
    # Error page
    get "error", to: "base#error", as: :error

    # Google OAuth
    get "google", to: "google#create", as: :google
    get "google/callback", to: "google#callback", as: :google_callback

    # GitHub OAuth
    get "github", to: "github#create", as: :github
    get "github/callback", to: "github#callback", as: :github_callback

    # Auth0 OAuth
    get "auth0", to: "auth0#create", as: :auth0
    get "auth0/callback", to: "auth0#callback", as: :auth0_callback
  end

  # Workspace switching
  post("/workspaces/:id/switch", to: "workspaces#switch", as: :switch_workspace)

  namespace(:admin) do
    root(to: "dashboard#index")
  end

  root(to: "static#index")
end
