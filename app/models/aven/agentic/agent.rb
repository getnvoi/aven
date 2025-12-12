# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_agents
#
#  id                   :bigint           not null, primary key
#  enabled              :boolean          default(TRUE), not null
#  label                :string           not null
#  slug                 :string
#  system_prompt        :text
#  user_facing_question :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  workspace_id         :bigint           not null
#
# Indexes
#
#  index_aven_agentic_agents_on_enabled                (enabled)
#  index_aven_agentic_agents_on_workspace_id           (workspace_id)
#  index_aven_agentic_agents_on_workspace_id_and_slug  (workspace_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  module Agentic
    class Agent < Aven::ApplicationRecord
      self.table_name = "aven_agentic_agents"

      include Aven::Model::TenantModel

      extend FriendlyId
      friendly_id :label, use: [:slugged, :scoped], scope: :workspace

      has_many :agent_tools,
               class_name: "Aven::Agentic::AgentTool",
               foreign_key: :agent_id,
               dependent: :destroy,
               inverse_of: :agent

      has_many :tools, through: :agent_tools

      has_many :agent_documents,
               class_name: "Aven::Agentic::AgentDocument",
               foreign_key: :agent_id,
               dependent: :destroy,
               inverse_of: :agent

      has_many :documents, through: :agent_documents

      has_many :threads,
               class_name: "Aven::Chat::Thread",
               foreign_key: :agent_id,
               dependent: :nullify

      accepts_nested_attributes_for :agent_tools, allow_destroy: true
      accepts_nested_attributes_for :agent_documents, allow_destroy: true

      validates :label, presence: true

      scope :enabled, -> { where(enabled: true) }

      # Returns tool names for this agent (used when locking thread tools)
      def tool_names
        tools.pluck(:name)
      end

      # Returns document IDs for this agent (used when locking thread documents)
      def document_ids
        documents.pluck(:id)
      end
    end
  end
end
