# frozen_string_literal: true

module Aven::Views::Auth::PasswordResets::Edit
  class Component < Aven::ApplicationViewComponent
    option :token
    option :alert, optional: true

    def form_path
      Aven::Engine.routes.url_helpers.auth_password_reset_path
    end

    def minimum_length
      Aven.configuration.password_minimum_length
    end
  end
end
