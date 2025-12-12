# frozen_string_literal: true

module Aven
  module Chat
    class RunJob < Aven::ApplicationJob
      queue_as :default

      def perform(thread_id, user_message_id = nil)
        thread = Aven::Chat::Thread.find_by(id: thread_id)
        return unless thread

        user_message = if user_message_id
          thread.messages.find_by(id: user_message_id)
        else
          thread.messages.where(role: :user).order(:created_at).last
        end

        return unless user_message

        Aven::Chat::Orchestrator.new(thread).run(user_message)
      rescue => e
        Rails.logger.error("[Aven::Chat] RunJob failed for thread #{thread_id}: #{e.message}")
        Rails.logger.error(e.backtrace.first(10).join("\n"))
      end
    end
  end
end
