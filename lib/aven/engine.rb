require "devise"
require "omniauth"
require "omniauth/rails_csrf_protection"
require "repost"
require "importmap-rails"
require "view_component-contrib"
require "dry-effects"
require "tailwind_merge"
require "json_skooma"
require "aeros"

module Aven
  class << self
    attr_accessor :importmap
  end

  class Engine < ::Rails::Engine
    isolate_namespace Aven

    Aeros::EngineHelpers.setup_assets(self, namespace: Aven)
    Aeros::EngineHelpers.setup_importmap(self, namespace: Aven)

    # Ensure migrations are available to the host app
    initializer "aven.migrations" do
      unless Rails.env.test? || Rails.application.class.module_parent_name == "Dummy"
        config.paths["db/migrate"].expanded.each do |expanded_path|
          Rails.application.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    initializer "aven.devise", after: :load_config_initializers do
      # Configure OmniAuth providers from Aven configuration
      providers = Aven.configuration.auth.providers

      # Add OmniAuth middleware
      Rails.application.config.middleware.use OmniAuth::Builder do
        providers.each do |provider_config|
          provider provider_config[:provider], *provider_config[:args], **provider_config[:options]
        end
      end
    end
  end
end
