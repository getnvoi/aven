# frozen_string_literal: true

module Aeno
  module Primitives
    module Link
      class Component < Aeno::ApplicationViewComponent
        option :label
        option :href
        option :variant, default: -> { :default }
        option :size, default: -> { :base }
        option :css, optional: true

        def variant_class
          case variant
          when :muted then "text-muted-foreground hover:text-foreground"
          when :underline then "underline underline-offset-4"
          else "text-primary hover:underline"
          end
        end

        def size_class
          case size
          when :sm then "text-sm"
          when :lg then "text-lg"
          else "text-base"
          end
        end

        def classes
          [variant_class, size_class, css].compact.join(" ")
        end
      end
    end
  end
end
