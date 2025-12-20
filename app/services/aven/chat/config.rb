# frozen_string_literal: true

module Aven
  module Chat
    class Config
      DEFAULT_MODEL = "claude-sonnet-4-5-20250929"
      DEFAULT_SYSTEM_PROMPT = "You are a helpful assistant."

      class << self
        def model
          Aven.configuration.agentic&.default_model || DEFAULT_MODEL
        end

        def system_prompt(user: nil, thread: nil)
          base_system_prompt
        end

        # Returns tools available for a thread.
        # - If thread.tools is nil: all tools are available (free-form chat)
        # - If thread.tools is an array: only those tools are available (locked)
        def tools(thread = nil)
          workspace = thread&.workspace
          return [] unless workspace

          # Get all active feature tools for the workspace
          all_tools = Aven::FeatureTool
            .joins(:feature)
            .where(aven_features: { deleted_at: nil })
            .where(aven_feature_tools: { deleted_at: nil })
            .to_a

          return all_tools unless thread&.tools_locked?

          locked_names = thread.tools
          return [] if locked_names.empty?

          all_tools.select { |tool| locked_names.include?(tool.slug) }
        end

        # Calculate cost in USD based on token counts.
        def calculate_cost(input_tokens:, output_tokens:, model_id:)
          pricing = pricing_for(model_id)
          return nil unless pricing

          input_cost = (input_tokens.to_f / 1_000_000) * pricing[:input]
          output_cost = (output_tokens.to_f / 1_000_000) * pricing[:output]
          input_cost + output_cost
        end

        private

          def base_system_prompt
            configured = Aven.configuration.agentic&.system_prompt
            return configured.call if configured.respond_to?(:call)

            configured || DEFAULT_SYSTEM_PROMPT
          end

          def pricing_for(model_id)
            Rails.cache.fetch("aven/llm_pricing/#{model_id}", expires_in: 24.hours) do
              fetch_pricing(model_id)
            end
          end

          def fetch_pricing(model_id)
            return nil unless defined?(RubyLLM)

            model = RubyLLM.models.find(model_id)
            tier = model&.pricing&.text_tokens&.standard
            return nil unless tier

            { input: tier.input_per_million, output: tier.output_per_million }
          rescue
            nil
          end
      end
    end
  end
end
