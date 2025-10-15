module Aven::Views::Static::Index
  class Component < Aven::ApplicationViewComponent
    option(:current_user, optional: true)

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
  end
end
