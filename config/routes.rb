Aven::Engine.routes.draw do
  # Devise for session management only
  devise_for(
    :users, class_name: "Aven::User", module: :devise,
    skip: %w[registrations passwords confirmations omniauth_callbacks]
  )

  # Logout route (using Devise)
  devise_scope :user do
    get "/logout", to: "devise/sessions#destroy", as: :logout
  end

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
