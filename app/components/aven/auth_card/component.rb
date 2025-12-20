# frozen_string_literal: true

module Aven
  class AuthCard < Aeno::ApplicationViewComponent
    option :title
    option :subtitle, optional: true
    option :max_width, default: -> { :sm }

    renders_one :alert
    renders_one :footer

    def width_class
      case max_width
      when :sm then "max-w-sm"
      when :md then "max-w-md"
      when :lg then "max-w-lg"
      else "max-w-sm"
      end
    end
  end
end
