# frozen_string_literal: true

module Aven
  module Chat
    class Orchestrator
      def initialize(thread)
        @thread = thread
      end

      # Run chat for a user message
      # @param user_message [Aven::Chat::Message] The user's message
      def run(user_message)
        assistant_message = create_assistant_message(user_message)
        generate_title_if_first_message(user_message)

        begin
          messages = MessageBuilder.new(@thread).build
          response = Runner.new(@thread, assistant_message).run(messages)

          assistant_message.mark_completed!(
            content: response.content,
            model: response.model_id,
            tokens: {
              input: response.input_tokens,
              output: response.output_tokens,
              total: response.input_tokens + response.output_tokens
            }
          )

          # Calculate cost async
          CalculateCostJob.perform_later(assistant_message.id)
        rescue => e
          assistant_message.mark_failed!(e.message)
          raise
        end
      end

      private

        def create_assistant_message(user_message)
          message = @thread.messages.create!(
            role: :assistant,
            parent: user_message,
            status: :pending
          )
          message.mark_started!
          message
        end

        def generate_title_if_first_message(user_message)
          return unless first_user_message?(user_message)

          # Generate title in background thread
          ::Thread.new do
            TitleGenerator.new(@thread, user_message).call
          rescue => e
            Rails.logger.error("[Aven::Chat] Title generation error: #{e.message}")
          end
        end

        def first_user_message?(user_message)
          @thread.messages
            .where(role: :user)
            .where.not(id: user_message.id)
            .none?
        end
    end
  end
end
