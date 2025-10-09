module Aven
  class ApplicationViewComponent < Aeros::ApplicationViewComponent
    def controller_name
      # Match JS autoload naming for components/controllers:
      # - aven/controllers/hello_controller -> aven--hello
      # - aven/components/views/static/index/controller -> aven--views--static--index
      name = self.class.name
        .sub(/^Aven::/, "")
        .sub(/::Component$/, "")
        .underscore

      "aven--#{name.gsub('/', '--').gsub('_', '-')}"
    end
  end
end
