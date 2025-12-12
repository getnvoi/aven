# frozen_string_literal: true

module Aven
  module Agentic
    class ToolResultFormatter
      MAX_RESULT_LENGTH = 50_000

      class << self
        # Format tool result for LLM consumption
        # @param tool_name [String] Name of the tool
        # @param result [Object] Raw result from tool execution
        # @return [String] Formatted result string
        def format(tool_name, result)
          formatted = case result
          when Array
            format_array(result)
          when Hash
            format_hash(result)
          when nil
            "No results found."
          else
            result.to_s
          end

          truncate_if_needed(formatted)
        end

        private

          def format_array(results)
            return "No results found." if results.empty?

            items = results.map.with_index do |item, idx|
              case item
              when Hash
                format_hash_item(item, idx + 1)
              else
                "#{idx + 1}. #{item}"
              end
            end

            "Found #{results.size} result(s):\n\n#{items.join("\n\n")}"
          end

          def format_hash(result)
            result.map { |k, v| "#{k}: #{format_value(v)}" }.join("\n")
          end

          def format_hash_item(item, index)
            lines = item.map { |k, v| "  #{k}: #{format_value(v)}" }
            "#{index}.\n#{lines.join("\n")}"
          end

          def format_value(value)
            case value
            when Array
              value.join(", ")
            when Hash
              value.to_json
            when nil
              "N/A"
            else
              value.to_s
            end
          end

          def truncate_if_needed(text)
            return text if text.length <= MAX_RESULT_LENGTH

            truncated = text[0, MAX_RESULT_LENGTH]
            "#{truncated}\n\n[Result truncated - showing first #{MAX_RESULT_LENGTH} characters]"
          end
      end
    end
  end
end
