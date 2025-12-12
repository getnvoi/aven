# frozen_string_literal: true

module Aven
  module Agentic
    module Tools
      module Concerns
        module RangeFiltering
          extend ActiveSupport::Concern

          class_methods do
            # Define range filter parameters (min/max)
            def range_filterable(name, column:, type: :integer, desc: nil)
              @range_filters ||= {}
              @range_filters[name] = { column: }

              param_type = type == :integer ? :number : :number

              param "#{name}_min".to_sym,
                type: param_type,
                desc: desc || "Minimum #{name}",
                required: false

              param "#{name}_max".to_sym,
                type: param_type,
                desc: desc || "Maximum #{name}",
                required: false
            end

            def range_filters
              @range_filters || {}
            end
          end

          # Apply range filtering to a scope
          def apply_range_filters(scope, **params)
            self.class.range_filters.each do |name, config|
              column = config[:column]
              min_val = params["#{name}_min".to_sym]
              max_val = params["#{name}_max".to_sym]

              scope = scope.where("#{column} >= ?", min_val) if min_val.present?
              scope = scope.where("#{column} <= ?", max_val) if max_val.present?
            end

            scope
          end
        end
      end
    end
  end
end
