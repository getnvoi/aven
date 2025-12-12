# frozen_string_literal: true

module Aven
  module Agentic
    module Tools
      module Concerns
        module EnumFiltering
          extend ActiveSupport::Concern

          class_methods do
            # Define enum filter parameters
            def enum_filterable(name, column:, values:, desc: nil)
              @enum_filters ||= {}
              @enum_filters[name] = {
                column:,
                values:
              }

              param name, type: :string, desc: desc || "Filter by #{name}", required: false
            end

            def enum_filters
              @enum_filters || {}
            end
          end

          # Apply enum filtering to a scope
          def apply_enum_filters(scope, **params)
            self.class.enum_filters.each do |name, config|
              value = params[name]
              next if value.blank?

              column = config[:column]
              allowed = config[:values]

              if allowed.include?(value)
                scope = scope.where(column => value)
              end
            end

            scope
          end
        end
      end
    end
  end
end
