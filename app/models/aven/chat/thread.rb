# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_chat_threads
#
#  id               :bigint           not null, primary key
#  context_markdown :text
#  documents        :jsonb
#  title            :string
#  tools            :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  agent_id         :bigint
#  user_id          :bigint           not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  index_aven_chat_threads_on_agent_id                  (agent_id)
#  index_aven_chat_threads_on_created_at                (created_at)
#  index_aven_chat_threads_on_user_id                   (user_id)
#  index_aven_chat_threads_on_workspace_id              (workspace_id)
#  index_aven_chat_threads_on_workspace_id_and_user_id  (workspace_id,user_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => aven_agentic_agents.id)
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  module Chat
    class Thread < Aven::ApplicationRecord
      self.table_name = "aven_chat_threads"

      include Aven::Model::TenantModel

      belongs_to :user, class_name: "Aven::User"
      belongs_to :agent, class_name: "Aven::Agentic::Agent", optional: true

      has_many :messages,
               class_name: "Aven::Chat::Message",
               foreign_key: :thread_id,
               dependent: :destroy

      validates :user, presence: true

      after_update :broadcast_update, if: :saved_change_to_title?

      scope :recent, -> { order(created_at: :desc) }

      # Tools are locked on first agent use and never modified after.
      # - nil means all tools are available (free-form chat)
      # - Array of tool names means only those tools are available
      def tools_locked?
        tools.present?
      end

      # Lock tools to a specific set of tool names.
      def lock_tools!(tool_names)
        return if tools_locked?

        update!(tools: tool_names)
      end

      # Documents are locked on first agent use and never modified after.
      def documents_locked?
        documents.present?
      end

      # Lock documents to a specific set of document IDs.
      def lock_documents!(document_ids)
        return if documents_locked?
        return if document_ids.blank?

        update!(documents: document_ids)
      end

      # Returns the locked documents with OCR content for system prompt injection
      def locked_documents
        return [] unless documents_locked?

        Aven::Agentic::Document.where(id: documents).where(ocr_status: "completed")
      end

      # Check if thread has an agent locked
      def agent_locked?
        agent_id.present?
      end

      # Lock the agent reference. Called once when an agent is first used.
      def lock_agent!(agent)
        return if agent_locked?

        update!(agent:)
      end

      # Ask a question and trigger chat processing
      def ask(question)
        user_message = messages.create!(
          role: :user,
          content: question,
          status: :success
        )
        Aven::Chat::RunJob.perform_later(id, user_message.id)
        user_message
      end

      # Ask with an agent, locking agent/tools/documents on first use
      def ask_with_agent(agent, question = nil)
        unless agent_locked?
          lock_agent!(agent)
          lock_tools!(agent.tool_names)
          lock_documents!(agent.document_ids)
        end

        # Create hidden system message with agent's system prompt
        if agent.system_prompt.present?
          messages.create!(
            role: :system,
            content: agent.system_prompt,
            status: :success
          )
        end

        ask(question || agent.user_facing_question)
      end

      # Calculate usage statistics
      def usage_stats
        result = messages
          .where.not(role: :user)
          .pick(
            Arel.sql("SUM(input_tokens)"),
            Arel.sql("SUM(output_tokens)"),
            Arel.sql("SUM(total_tokens)"),
            Arel.sql("SUM(cost_usd)")
          )

        {
          input: result[0] || 0,
          output: result[1] || 0,
          total: result[2] || 0,
          cost: result[3] || 0.0
        }
      end

      private

        def broadcast_update
          Aven::Chat::ThreadChannel.broadcast_to(self, {
            type: "thread_update",
            thread: { id:, title: }
          })
        end
    end
  end
end
