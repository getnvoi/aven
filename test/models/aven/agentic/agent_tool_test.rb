# == Schema Information
#
# Table name: aven_agentic_agent_tools
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  agent_id   :bigint           not null
#  tool_id    :bigint           not null
#
# Indexes
#
#  index_aven_agentic_agent_tools_on_agent_id              (agent_id)
#  index_aven_agentic_agent_tools_on_agent_id_and_tool_id  (agent_id,tool_id) UNIQUE
#  index_aven_agentic_agent_tools_on_tool_id               (tool_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => aven_agentic_agents.id)
#  fk_rails_...  (tool_id => aven_agentic_tools.id)
#
require "test_helper"

class Aven::Agentic::AgentToolTest < ActiveSupport::TestCase
  # Associations
  test "belongs to agent" do
    agent_tool = aven_agentic_agent_tools(:research_agent_search)
    assert_respond_to agent_tool, :agent
    assert_equal aven_agentic_agents(:research_agent), agent_tool.agent
  end

  test "belongs to tool" do
    agent_tool = aven_agentic_agent_tools(:research_agent_search)
    assert_respond_to agent_tool, :tool
    assert_equal aven_agentic_tools(:search_tool), agent_tool.tool
  end

  # Validations
  test "valid with agent and tool" do
    agent_tool = Aven::Agentic::AgentTool.new(
      agent: aven_agentic_agents(:math_agent),
      tool: aven_agentic_tools(:search_tool)
    )
    assert agent_tool.valid?
  end

  test "requires agent" do
    agent_tool = Aven::Agentic::AgentTool.new(
      tool: aven_agentic_tools(:search_tool)
    )
    assert_not agent_tool.valid?
    assert_includes agent_tool.errors[:agent], "must exist"
  end

  test "requires tool" do
    agent_tool = Aven::Agentic::AgentTool.new(
      agent: aven_agentic_agents(:math_agent)
    )
    assert_not agent_tool.valid?
    assert_includes agent_tool.errors[:tool], "must exist"
  end

  # Creation through agent
  test "can be created through agent association" do
    agent = aven_agentic_agents(:math_agent)
    tool = aven_agentic_tools(:search_tool)

    agent.agent_tools.create!(tool: tool)

    assert_includes agent.tools.reload, tool
  end
end
