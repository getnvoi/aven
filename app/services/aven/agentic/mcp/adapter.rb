# frozen_string_literal: true

module Aven
  module Agentic
    module Mcp
      class Adapter
        def initialize(tool_class, context = {})
          @tool_class = tool_class
          @context = context
        end

        # Convert tool to MCP tool format
        def to_mcp_tool
          {
            name: tool_name,
            description: tool_description,
            input_schema: build_input_schema,
            handler: method(:handle)
          }
        end

        # Handle MCP tool call
        def handle(params)
          result = @tool_class.new.execute(**params.symbolize_keys)
          ResultFormatter.format(result)
        rescue => e
          Rails.logger.error("[Aven::MCP] Tool execution error: #{e.message}")
          ResultFormatter.format_error(e)
        end

        private

          def tool_name
            @tool_class.tool_name
          end

          def tool_description
            @tool_class.class.tool_record&.effective_description || "No description"
          end

          def build_input_schema
            properties = {}
            required = []

            tool_record = @tool_class.class.tool_record
            return { type: "object", properties: {} } unless tool_record

            tool_record.parameters.each do |param|
              properties[param.name] = {
                type: json_schema_type(param.param_type),
                description: param.effective_description
              }

              required << param.name if param.required?
            end

            {
              type: "object",
              properties:,
              required:
            }
          end

          def json_schema_type(param_type)
            case param_type.to_sym
            when :integer then "integer"
            when :float then "number"
            when :boolean then "boolean"
            when :array then "array"
            when :object then "object"
            else "string"
            end
          end
      end
    end
  end
end
