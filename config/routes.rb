Sqema::Engine.routes.draw do
  devise_for(
    :users, class_name: "Sqema::User", module: :devise, format: false,
    controllers: { omniauth_callbacks: "sqema/auth" }
  )

  # Additional auth routes
  get("/auth/:provider/authenticate", to: "auth#authenticate", as: :authenticate)
  get("/auth/logout", to: "auth#logout", as: :logout)

  root(to: "static#index")
end
