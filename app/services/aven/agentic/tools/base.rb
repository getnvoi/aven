# frozen_string_literal: true

module Aven
  module Agentic
    module Tools
      class Base
        # Parameter definition structure
        Parameter = Struct.new(:name, :type, :description, :required, :constraints, keyword_init: true) do
          def to_h
            super.compact
          end
        end

        class << self
          # Tool name for registry
          def tool_name
            name.demodulize.underscore
          end

          # Default description (must be overridden in subclasses)
          def default_description
            raise NotImplementedError, "#{name} must define default_description"
          end

          # Parameter definitions - override in subclasses
          # @return [Array<Parameter>]
          def parameters
            @parameters ||= []
          end

          # DSL for defining parameters
          def param(name, type:, desc:, required: false, **constraints)
            parameters << Parameter.new(
              name: name,
              type: type,
              description: desc,
              required: required,
              constraints: constraints.presence
            )
          end

          # Get parameter by name
          def parameter(name)
            parameters.find { |p| p.name == name.to_sym }
          end

          # Main entry point - override in subclasses
          def call(**params)
            raise NotImplementedError, "#{name} must define call"
          end
        end
      end
    end
  end
end
