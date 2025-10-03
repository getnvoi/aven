module Sqema
  module ApplicationHelper
    def sqema_importmap_tags(entry_point = "application", shim: true)
      safe_join [
        javascript_inline_importmap_tag(Sqema.importmap.to_json(resolver: self)),
        javascript_importmap_module_preload_tags(Sqema.importmap),
        javascript_import_module_tag(entry_point)
      ].compact, "\n"
    end

    def view_component(name, *args, status: nil, **kwargs, &block)
      component = "Sqema::Views::#{name.split("/").map(&:camelize).join("::")}::Component".constantize
      if status
        render(component.new(*args, **kwargs), status:, &block)
      else
        render(component.new(*args, **kwargs), &block)
      end
    end

    def ui(name, *args, **kwargs, &block)
      component = "Sqema::Ui::#{name.to_s.camelize}::Component".constantize
      render(component.new(*args, **kwargs), &block)
    end
  end
end
