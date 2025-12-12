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

  namespace(:admin) do
    root(to: "dashboard#index")
  end

  root(to: "static#index")
end
