# frozen_string_literal: true

module Aven
  module Agentic
    module Mcp
      class ResultFormatter
        class << self
          # Format successful result for MCP response
          # @param result [Object] Tool execution result
          # @return [Hash] MCP-formatted result
          def format(result)
            {
              content: [
                {
                  type: "text",
                  text: format_content(result)
                }
              ]
            }
          end

          # Format error for MCP response
          # @param error [Exception] Error that occurred
          # @return [Hash] MCP-formatted error
          def format_error(error)
            {
              content: [
                {
                  type: "text",
                  text: "Error: #{error.message}"
                }
              ],
              isError: true
            }
          end

          private

            def format_content(result)
              case result
              when String
                result
              when Hash
                JSON.pretty_generate(result)
              when Array
                result.map { |item| format_content(item) }.join("\n\n")
              when nil
                "No result"
              else
                result.to_s
              end
            end
        end
      end
    end
  end
end
