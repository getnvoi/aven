# frozen_string_literal: true

module Aven::Views::Auth::Registrations::New
  class Component < Aven::ApplicationViewComponent
    option :email, optional: true
    option :alert, optional: true

    def form_path
      Aven::Engine.routes.url_helpers.auth_register_path
    end

    def login_path
      Aven::Engine.routes.url_helpers.auth_login_path
    end

    def minimum_length
      Aven.configuration.password_minimum_length
    end
  end
end
