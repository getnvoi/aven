# frozen_string_literal: true

module Aven
  module Agentic
    module Tools
      module Concerns
        module BooleanFiltering
          extend ActiveSupport::Concern

          class_methods do
            # Define boolean filter parameters
            def boolean_filterable(name, column:, desc: nil)
              @boolean_filters ||= {}
              @boolean_filters[name] = { column: column }

              param name, type: :boolean, desc: desc || "Filter by #{name}", required: false
            end

            def boolean_filters
              @boolean_filters || {}
            end
          end

          # Apply boolean filtering to a scope
          def apply_boolean_filters(scope, **params)
            self.class.boolean_filters.each do |name, config|
              value = params[name]
              next if value.nil?

              column = config[:column]
              scope = scope.where(column => value)
            end

            scope
          end
        end
      end
    end
  end
end
