# frozen_string_literal: true

module Aven
  module Chat
    class MessageBuilder
      def initialize(thread)
        @thread = thread
      end

      # Build message array for LLM from thread history
      # @return [Array<Hash>] Messages in LLM format
      def build
        @thread.messages
          .chronological
          .where.not(role: :tool)  # Tool messages handled separately
          .where(status: :success)
          .map { |msg| format_message(msg) }
          .compact
      end

      private

        def format_message(message)
          return nil if message.content.blank? && !message.role_system?

          {
            role: llm_role(message.role),
            content: message.content || ""
          }
        end

        def llm_role(role)
          case role.to_sym
          when :user then :user
          when :assistant then :assistant
          when :system then :system
          else :user
          end
        end
    end
  end
end
