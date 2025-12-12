# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_chat_messages
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  content       :text
#  cost_usd      :decimal(10, 6)   default(0.0)
#  input_tokens  :integer          default(0)
#  model         :string
#  output_tokens :integer          default(0)
#  role          :string           not null
#  started_at    :datetime
#  status        :string           default("pending")
#  tool_call     :jsonb
#  total_tokens  :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :bigint
#  thread_id     :bigint           not null
#
# Indexes
#
#  index_aven_chat_messages_on_parent_id                 (parent_id)
#  index_aven_chat_messages_on_role                      (role)
#  index_aven_chat_messages_on_status                    (status)
#  index_aven_chat_messages_on_thread_id                 (thread_id)
#  index_aven_chat_messages_on_thread_id_and_created_at  (thread_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => aven_chat_messages.id)
#  fk_rails_...  (thread_id => aven_chat_threads.id)
#
module Aven
  module Chat
    class Message < Aven::ApplicationRecord
      self.table_name = "aven_chat_messages"

      belongs_to :thread, class_name: "Aven::Chat::Thread"
      belongs_to :parent, class_name: "Aven::Chat::Message", optional: true

      has_many :replies,
               class_name: "Aven::Chat::Message",
               foreign_key: :parent_id,
               dependent: :nullify

      enum :role, {
        user: "user",
        assistant: "assistant",
        tool: "tool",
        system: "system"
      }, prefix: true

      enum :status, {
        pending: "pending",
        streaming: "streaming",
        success: "success",
        error: "error"
      }, prefix: true, default: :pending

      validates :thread, :role, presence: true
      validates :content, presence: true, unless: -> { role_assistant? && (status_pending? || status_streaming?) }

      scope :by_tool_call_id, ->(id) { where("tool_call->>'id' = ?", id) }
      scope :chronological, -> { order(:created_at) }

      after_create_commit :broadcast_created
      after_update_commit :broadcast_updated

      # Calculate duration if timing is available
      def duration
        return nil unless started_at && completed_at

        completed_at - started_at
      end

      def mark_started!
        update!(started_at: Time.current, status: :streaming)
      end

      def mark_completed!(content: nil, model: nil, tokens: {})
        update!(
          completed_at: Time.current,
          status: :success,
          content:,
          model:,
          input_tokens: tokens[:input] || 0,
          output_tokens: tokens[:output] || 0,
          total_tokens: tokens[:total] || 0
        )
      end

      def mark_failed!(error_message)
        update!(
          completed_at: Time.current,
          status: :error,
          content: error_message
        )
      end

      # Append content during streaming
      def append_content!(chunk)
        new_content = (content || "") + chunk
        update_column(:content, new_content)
        broadcast_streaming(new_content)
      end

      private

        def broadcast_created
          Aven::Chat::ThreadChannel.broadcast_to(thread, {
            type: "message_created",
            message: as_json
          })
        end

        def broadcast_updated
          Aven::Chat::ThreadChannel.broadcast_to(thread, {
            type: "message_updated",
            message: as_json
          })
        end

        def broadcast_streaming(content)
          Aven::Chat::ThreadChannel.broadcast_to(thread, {
            type: "message_streaming",
            message: { id:, content: }
          })
        end
    end
  end
end
