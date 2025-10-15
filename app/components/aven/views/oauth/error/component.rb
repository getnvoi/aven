module Aven::Views::Oauth::Error
  class Component < Aven::ApplicationViewComponent
    option :error_message
    option :error_class, optional: true
    option :current_user, optional: true

    def provider_links
      Aven.configuration.oauth_providers.keys
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

    def home_path
      if helpers.respond_to?(:main_app) && helpers.main_app.respond_to?(:root_path)
        helpers.main_app.root_path
      else
        Aven::Engine.routes.url_helpers.root_path
      end
    end
  end
end
