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
require "test_helper"

class Aven::Agentic::AgentDocumentTest < ActiveSupport::TestCase
  # Associations
  test "belongs to agent" do
    agent_doc = aven_agentic_agent_documents(:research_agent_pdf)
    assert_respond_to agent_doc, :agent
    assert_equal aven_agentic_agents(:research_agent), agent_doc.agent
  end

  test "belongs to document" do
    agent_doc = aven_agentic_agent_documents(:research_agent_pdf)
    assert_respond_to agent_doc, :document
    assert_equal aven_agentic_documents(:pdf_document), agent_doc.document
  end

  # Validations
  test "valid with agent and document" do
    agent_doc = Aven::Agentic::AgentDocument.new(
      agent: aven_agentic_agents(:math_agent),
      document: aven_agentic_documents(:image_document)
    )
    assert agent_doc.valid?
  end

  test "requires agent" do
    agent_doc = Aven::Agentic::AgentDocument.new(
      document: aven_agentic_documents(:pdf_document)
    )
    assert_not agent_doc.valid?
    assert_includes agent_doc.errors[:agent], "must exist"
  end

  test "requires document" do
    agent_doc = Aven::Agentic::AgentDocument.new(
      agent: aven_agentic_agents(:math_agent)
    )
    assert_not agent_doc.valid?
    assert_includes agent_doc.errors[:document], "must exist"
  end

  # Creation through agent
  test "can be created through agent association" do
    agent = aven_agentic_agents(:math_agent)
    doc = aven_agentic_documents(:image_document)

    agent.agent_documents.create!(document: doc)

    assert_includes agent.documents.reload, doc
  end
end
