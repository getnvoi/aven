# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_agent_documents
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  agent_id    :bigint           not null
#  document_id :bigint           not null
#
# Indexes
#
#  index_aven_agentic_agent_documents_on_agent_id                  (agent_id)
#  index_aven_agentic_agent_documents_on_agent_id_and_document_id  (agent_id,document_id) UNIQUE
#  index_aven_agentic_agent_documents_on_document_id               (document_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => aven_agentic_agents.id)
#  fk_rails_...  (document_id => aven_agentic_documents.id)
#
module Aven
  module Agentic
    class AgentDocument < Aven::ApplicationRecord
      self.table_name = "aven_agentic_agent_documents"

      belongs_to :agent, class_name: "Aven::Agentic::Agent", inverse_of: :agent_documents
      belongs_to :document, class_name: "Aven::Agentic::Document", inverse_of: :agent_documents

      validates :document_id, uniqueness: { scope: :agent_id }

      delegate :workspace, :workspace_id, to: :agent
    end
  end
end
