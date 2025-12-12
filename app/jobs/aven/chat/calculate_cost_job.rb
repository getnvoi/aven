# frozen_string_literal: true

module Aven
  module Chat
    class CalculateCostJob < Aven::ApplicationJob
      queue_as :low

      def perform(message_id)
        message = Aven::Chat::Message.find_by(id: message_id)
        return unless message
        return unless message.model.present?
        return if message.cost_usd > 0

        cost = Config.calculate_cost(
          input_tokens: message.input_tokens,
          output_tokens: message.output_tokens,
          model_id: message.model
        )

        message.update!(cost_usd: cost) if cost
      rescue => e
        Rails.logger.warn("[Aven::Chat] Cost calculation failed for message #{message_id}: #{e.message}")
      end
    end
  end
end
