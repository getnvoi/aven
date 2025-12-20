# frozen_string_literal: true

module Aeno
  module Primitives
    module Alert
      class Component < Aeno::ApplicationViewComponent
        option :message
        option :variant, default: -> { :default }
        option :title, optional: true
        option :dismissible, default: -> { false }

        def variant_classes
          case variant
          when :error then "bg-red-50 text-red-900 border-red-200"
          when :success then "bg-green-50 text-green-900 border-green-200"
          when :warning then "bg-yellow-50 text-yellow-900 border-yellow-200"
          when :info then "bg-blue-50 text-blue-900 border-blue-200"
          else "bg-gray-50 text-gray-900 border-gray-200"
          end
        end
      end
    end
  end
end
