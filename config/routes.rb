Aven::Engine.routes.draw do
  devise_for(
    :users, class_name: "Aven::User", module: :devise, format: false,
    controllers: { omniauth_callbacks: "aven/auth" }
  )

  # Additional auth routes
  get("/auth/:provider/authenticate", to: "auth#authenticate", as: :authenticate)
  get("/auth/logout", to: "auth#logout", as: :logout)

  namespace(:admin) do
    root(to: "dashboard#index")
  end

  root(to: "static#index")
end
