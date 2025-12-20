# frozen_string_literal: true

module Aven::Views::Auth::MagicLinks::New
  class Component < Aven::ApplicationViewComponent
    option :email, optional: true
    option :alert, optional: true

    def form_path
      Aven::Engine.routes.url_helpers.auth_magic_link_path
    end

    def oauth_providers
      Aven.configuration.oauth_providers.keys.select do |provider|
        Aven.configuration.oauth_configured?(provider)
      end
    end

    def oauth_path_for(provider)
      case provider.to_sym
      when :github
        Aven::Engine.routes.url_helpers.oauth_github_path
      when :google
        Aven::Engine.routes.url_helpers.oauth_google_path
      else
        "#"
      end
    end

    def show_oauth_providers?
      oauth_providers.any?
    end
  end
end
