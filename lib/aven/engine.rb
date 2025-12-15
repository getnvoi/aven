require "importmap-rails"
require "view_component-contrib"
require "dry-effects"
require "json_skooma"
require "aeno"
require "friendly_id"
require "acts-as-taggable-on"
require "aven/model"

module Aven
  class << self
    attr_accessor :importmap
  end

  class Engine < ::Rails::Engine
    isolate_namespace Aven

    Aeno::EngineHelpers.setup_assets(self, namespace: Aven)
    Aeno::EngineHelpers.setup_importmap(self, namespace: Aven)

    # Append engine migrations to the main app
    initializer :append_migrations do |app|
      unless app.root.to_s.include?("test/dummy")
        config.paths["db/migrate"].expanded.each do |expanded_path|
          app.config.paths["db/migrate"] << expanded_path
        end
      end
    end

    # Include engine route helpers, authentication, and controller helpers in controllers and views
    initializer "aven.helpers" do
      ActiveSupport.on_load(:action_controller) do
        include Aven::Engine.routes.url_helpers
        include Aven::Authentication
        include Aven::ControllerHelpers
      end

      ActiveSupport.on_load(:action_view) do
        include Aven::Engine.routes.url_helpers
      end
    end
  end
end
