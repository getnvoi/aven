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
require "test_helper"

class Aven::Agentic::AgentTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :workspace
    assert_equal aven_workspaces(:one), agent.workspace
  end

  test "has many agent_tools" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :agent_tools
    assert_kind_of ActiveRecord::Associations::CollectionProxy, agent.agent_tools
  end

  test "has many tools through agent_tools" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :tools
    assert_includes agent.tools, aven_agentic_tools(:search_tool)
  end

  test "has many agent_documents" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :agent_documents
    assert_kind_of ActiveRecord::Associations::CollectionProxy, agent.agent_documents
  end

  test "has many documents through agent_documents" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :documents
    assert_includes agent.documents, aven_agentic_documents(:pdf_document)
  end

  test "has many threads" do
    agent = aven_agentic_agents(:research_agent)
    assert_respond_to agent, :threads
    assert_includes agent.threads, aven_chat_threads(:agent_thread)
  end

  test "destroying agent nullifies threads" do
    agent = aven_agentic_agents(:research_agent)
    thread = aven_chat_threads(:agent_thread)

    agent.destroy!
    thread.reload

    assert_nil thread.agent_id
  end

  # Validations
  test "validates presence of label" do
    agent = Aven::Agentic::Agent.new(workspace: aven_workspaces(:one))
    assert_not agent.valid?
    assert_includes agent.errors[:label], "can't be blank"
  end

  test "valid with required attributes" do
    agent = Aven::Agentic::Agent.new(
      workspace: aven_workspaces(:one),
      label: "New Agent"
    )
    assert agent.valid?
  end

  # FriendlyId
  test "generates slug from label" do
    agent = Aven::Agentic::Agent.create!(
      workspace: aven_workspaces(:one),
      label: "My New Agent"
    )
    assert_equal "my-new-agent", agent.slug
  end

  test "slug is scoped to workspace" do
    # Create agent in workspace one
    agent1 = Aven::Agentic::Agent.create!(
      workspace: aven_workspaces(:one),
      label: "Unique Agent"
    )

    # Create agent with same label in workspace two
    agent2 = Aven::Agentic::Agent.create!(
      workspace: aven_workspaces(:two),
      label: "Unique Agent"
    )

    assert_equal "unique-agent", agent1.slug
    assert_equal "unique-agent", agent2.slug
  end

  # Scopes
  test "enabled scope returns only enabled agents" do
    enabled = Aven::Agentic::Agent.enabled
    assert_includes enabled, aven_agentic_agents(:research_agent)
    assert_includes enabled, aven_agentic_agents(:math_agent)
    assert_not_includes enabled, aven_agentic_agents(:disabled_agent)
  end

  # TenantModel
  test "includes TenantModel concern" do
    assert Aven::Agentic::Agent.include?(Aven::Model::TenantModel)
  end

  test "in_workspace scope returns agents for workspace" do
    agents = Aven::Agentic::Agent.in_workspace(aven_workspaces(:one))
    assert_includes agents, aven_agentic_agents(:research_agent)
    assert_not_includes agents, aven_agentic_agents(:workspace_two_agent)
  end

  # Instance methods
  test "tool_names returns array of tool names" do
    agent = aven_agentic_agents(:research_agent)
    assert_equal ["search"], agent.tool_names
  end

  test "document_ids returns array of document IDs" do
    agent = aven_agentic_agents(:research_agent)
    doc_ids = agent.document_ids
    assert_includes doc_ids, aven_agentic_documents(:pdf_document).id
    assert_includes doc_ids, aven_agentic_documents(:word_document).id
  end

  # Nested attributes
  test "accepts nested attributes for agent_tools" do
    agent = Aven::Agentic::Agent.new(
      workspace: aven_workspaces(:one),
      label: "Test Agent",
      agent_tools_attributes: [
        { tool_id: aven_agentic_tools(:calculator_tool).id }
      ]
    )
    assert agent.valid?
    agent.save!
    assert_equal 1, agent.agent_tools.count
  end

  test "accepts nested attributes for agent_documents" do
    agent = Aven::Agentic::Agent.new(
      workspace: aven_workspaces(:one),
      label: "Test Agent",
      agent_documents_attributes: [
        { document_id: aven_agentic_documents(:pdf_document).id }
      ]
    )
    assert agent.valid?
    agent.save!
    assert_equal 1, agent.agent_documents.count
  end
end
