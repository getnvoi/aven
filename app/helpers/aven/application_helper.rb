module Aven
  module ApplicationHelper
    def aven_importmap_tags(entry_point = "application", shim: true)
      safe_join [
        javascript_inline_importmap_tag(Aven.importmap.to_json(resolver: self)),
        javascript_importmap_module_preload_tags(Aven.importmap),
        javascript_import_module_tag(entry_point)
      ].compact, "\n"
    end

    def view_component(name, *args, **kwargs, &block)
      component = "Aven::Views::#{name.split("/").map(&:camelize).join("::")}::Component".constantize
      render(component.new(*args, **kwargs), &block)
    end
  end
end
