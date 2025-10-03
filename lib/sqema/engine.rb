require "devise"
require "omniauth"
require "omniauth-github"
require "omniauth-google-oauth2"
require "omniauth/rails_csrf_protection"
require "repost"
require "importmap-rails"
require "view_component-contrib"
require "dry-effects"
require "tailwind_merge"
require "random_username"

module Sqema
  class << self
    attr_accessor :importmap
  end

  class Engine < ::Rails::Engine
    isolate_namespace Sqema

    # Support both Propshaft and Sprockets
    initializer "sqema.assets" do |app|
      if app.config.respond_to?(:assets)
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("app/components")
      end
    end

    # Ensure migrations are available to the host app
    initializer "sqema.migrations" do
      unless Rails.env.test? || Rails.application.class.module_parent_name == "Dummy"
        config.paths["db/migrate"].expanded.each do |expanded_path|
          Rails.application.config.paths["db/migrate"] << expanded_path
        end
      end
    end
    
    initializer "sqema.importmap", before: "importmap" do |app|
      Sqema.importmap = Importmap::Map.new
      Sqema.importmap.draw(app.root.join("config/importmap.rb"))
      Sqema.importmap.draw(root.join("config/importmap.rb"))
      Sqema.importmap.cache_sweeper(watches: root.join("app/javascript"))
      Sqema.importmap.cache_sweeper(watches: root.join("app/components"))

      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb")
      end

      ActiveSupport.on_load(:action_controller_base) do
        before_action { Sqema.importmap.cache_sweeper.execute_if_updated }
      end
    end

    initializer "sqema.devise", after: :load_config_initializers do
      # Configure OmniAuth providers from Sqema configuration
      providers = Sqema.configuration.auth.providers

      # Add OmniAuth middleware
      Rails.application.config.middleware.use OmniAuth::Builder do
        providers.each do |provider_config|
          provider provider_config[:provider], *provider_config[:args], **provider_config[:options]
        end
      end
    end
  end
end
