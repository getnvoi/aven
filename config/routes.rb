Aven::Engine.routes.draw do
  # Logout route
  get(:logout, to: "auth#logout", as: :logout)

  # Session management routes
  resources :sessions, only: [:index, :destroy] do
    collection do
      delete :revoke_all
    end
  end

  # Authentication routes
  namespace :auth do
    # Password login
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"

    # Magic link authentication
    get "magic_link", to: "magic_links#new", as: :magic_link
    post "magic_link", to: "magic_links#create"
    get "magic_link/verify", to: "magic_links#verify", as: :verify_magic_link
    post "magic_link/consume", to: "magic_links#consume", as: :consume_magic_link

    # Password reset
    get "password_reset", to: "password_resets#new", as: :password_reset
    post "password_reset", to: "password_resets#create"
    get "password_reset/edit", to: "password_resets#edit", as: :edit_password_reset
    patch "password_reset", to: "password_resets#update"

    # Password registration
    get "register", to: "registrations#new", as: :register
    post "register", to: "registrations#create"
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

  # Agentic API routes
  namespace :agentic do
    # MCP endpoint
    match "mcp", to: "mcp#handle", via: [:get, :post, :delete], as: :mcp
    get "mcp/health", to: "mcp#health", as: :mcp_health

    resources :agents, only: [:index, :show, :create, :update, :destroy]
    resources :tools, only: [:index, :show, :update]
    resources :documents, only: [:index, :show, :create, :destroy]
  end

  # Chat API routes
  namespace :chat do
    resources :threads, only: [:index, :show, :create] do
      member do
        post :ask
        post :ask_agent
      end
    end
  end

  # AI text generation (SSE streaming)
  namespace :ai do
    post "text/generate", to: "text#generate", as: :text_generate
  end

  # Tags API (for tagging component)
  resources :tags, only: [:index, :create]

  # Articles
  resources :articles

  # Gateway (public access via invite links)
  namespace :gateway, path: "g" do
    get "i/:auth_link_hash", to: "invite_fulfillment#show", as: :invite_fulfillment
  end

  namespace(:admin) do
    root(to: "dashboard#index")
  end

  # System Admin routes
  namespace :system do
    root to: "dashboard#index"

    # Authentication
    get "login", to: "sessions#new", as: :login
    post "login", to: "sessions#create"
    delete "logout", to: "sessions#destroy", as: :logout

    # System resources
    resources :activities, only: [:index]
    resources :contacts, only: [:index]
    resources :features, only: [:index, :show, :edit, :update]
    resources :invites, only: [:index]
    resources :users, only: [:index]
    resources :workspaces, only: [:index]

    # Impersonation
    post "impersonate/:user_id", to: "impersonations#create", as: :impersonate
    delete "impersonate", to: "impersonations#destroy", as: :stop_impersonation
  end

  root(to: "static#index")
end
