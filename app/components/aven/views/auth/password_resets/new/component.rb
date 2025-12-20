# frozen_string_literal: true

module Aven::Views::Auth::PasswordResets::New
  class Component < Aven::ApplicationViewComponent
    option :email, optional: true
    option :alert, optional: true

    def form_path
      Aven::Engine.routes.url_helpers.auth_password_reset_path
    end

    def login_path
      Aven::Engine.routes.url_helpers.auth_login_path
    end
  end
end
