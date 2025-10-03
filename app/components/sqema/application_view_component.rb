module Sqema
  class ApplicationViewComponent < ViewComponentContrib::Base
    extend(Dry::Initializer)
    include(Sqema::ApplicationHelper)
    include(ViewComponentContrib::StyleVariants)

    style_config.postprocess_with do |classes|
      TailwindMerge::Merger.new.merge(classes.join(" "))
    end

    option(:css, optional: true)
    def default_styles
      [style, css].join(" ")
    end

    class << self
      def named
        @named ||= self.name.sub(/::Component$/, "").underscore.split("/").join("--").gsub("_", "-")
      end
    end

    def controller_name
      # Match JS autoload naming for components/controllers:
      # - sqema/controllers/hello_controller -> sqema--hello
      # - sqema/components/ui/button/button_controller -> sqema--ui--button
      # - sqema/components/app/static/index/controller -> sqema--app--static--index
      name = self.class.name
        .sub(/^Sqema::/, "")
        .sub(/::Component$/, "")
        .underscore

      "sqema--#{name.gsub('/', '--').gsub('_', '-')}"
    end

    def data_target_key
      "#{controller_name}-target"
    end

    # Helper methods for Stimulus attributes
    # These return keys suited for Rails `data:` hashes (no `data-` prefix)
    def stimulus_controller
      { controller: controller_name }
    end

    def stimulus_target(name)
      { "#{controller_name}-target" => name }
    end

    def stimulus_action(event, method = nil)
      method ||= event
      { action: "#{event}->#{controller_name}##{method}" }
    end

    def stimulus_value(name, value)
      { "#{controller_name}-#{name}-value" => value }
    end

    def stimulus_class(name, css_class)
      { "#{controller_name}-#{name}-class" => css_class }
    end

    # Attribute helpers for raw tag helpers (already include `data-` prefix)
    def stimulus_attr_target(name)
      { "data-#{controller_name}-target" => name }
    end

    def merged_data
      return default_data unless respond_to?(:data) && data.keys

      data.merge(**default_data)
    end

    def default_data
      { controller: controller_name }
    end
  end
end
