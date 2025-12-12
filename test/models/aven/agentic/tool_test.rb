# == Schema Information
#
# Table name: aven_agentic_tools
#
#  id                  :bigint           not null, primary key
#  class_name          :string           not null
#  default_description :text
#  description         :text
#  enabled             :boolean          default(TRUE), not null
#  name                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  workspace_id        :bigint
#
# Indexes
#
#  index_aven_agentic_tools_on_enabled                      (enabled)
#  index_aven_agentic_tools_on_workspace_id                 (workspace_id)
#  index_aven_agentic_tools_on_workspace_id_and_class_name  (workspace_id,class_name) UNIQUE
#  index_aven_agentic_tools_on_workspace_id_and_name        (workspace_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

class Aven::Agentic::ToolTest < ActiveSupport::TestCase
  # Associations
  test "belongs to workspace (optional)" do
    tool = aven_agentic_tools(:search_tool)
    assert_respond_to tool, :workspace
    assert_equal aven_workspaces(:one), tool.workspace
  end

  test "global tool has no workspace" do
    tool = aven_agentic_tools(:global_tool)
    assert_nil tool.workspace
  end

  test "has many parameters" do
    tool = aven_agentic_tools(:search_tool)
    assert_respond_to tool, :parameters
    assert_includes tool.parameters, aven_agentic_tool_parameters(:search_query)
    assert_includes tool.parameters, aven_agentic_tool_parameters(:search_limit)
  end

  test "has many agent_tools" do
    tool = aven_agentic_tools(:search_tool)
    assert_respond_to tool, :agent_tools
    assert_kind_of ActiveRecord::Associations::CollectionProxy, tool.agent_tools
  end

  test "has many agents through agent_tools" do
    tool = aven_agentic_tools(:search_tool)
    assert_respond_to tool, :agents
    assert_includes tool.agents, aven_agentic_agents(:research_agent)
  end

  # Validations
  test "validates presence of name" do
    tool = Aven::Agentic::Tool.new(class_name: "SomeClass")
    assert_not tool.valid?
    assert_includes tool.errors[:name], "can't be blank"
  end

  test "validates presence of class_name" do
    tool = Aven::Agentic::Tool.new(name: "some_tool")
    assert_not tool.valid?
    assert_includes tool.errors[:class_name], "can't be blank"
  end

  test "validates uniqueness of name scoped to workspace" do
    duplicate = Aven::Agentic::Tool.new(
      workspace: aven_workspaces(:one),
      name: "search",
      class_name: "AnotherClass"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows same name in different workspaces" do
    # search tool exists in workspace one, create one with same name in workspace two
    new_tool = Aven::Agentic::Tool.new(
      workspace: aven_workspaces(:two),
      name: "calculator", # calculator exists in workspace one but not two
      class_name: "Aven::Agentic::Tools::Calculator"
    )
    assert new_tool.valid?, "Tool should be valid in different workspace: #{new_tool.errors.full_messages.join(', ')}"
  end

  test "validates uniqueness of class_name scoped to workspace" do
    duplicate = Aven::Agentic::Tool.new(
      workspace: aven_workspaces(:one),
      name: "new_search",
      class_name: "Aven::Agentic::Tools::Search"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:class_name], "has already been taken"
  end

  # Scopes
  test "enabled scope returns only enabled tools" do
    enabled = Aven::Agentic::Tool.enabled
    assert_includes enabled, aven_agentic_tools(:search_tool)
    assert_includes enabled, aven_agentic_tools(:calculator_tool)
    assert_not_includes enabled, aven_agentic_tools(:disabled_tool)
  end

  test "global scope returns tools without workspace" do
    global = Aven::Agentic::Tool.global
    assert_includes global, aven_agentic_tools(:global_tool)
    assert_not_includes global, aven_agentic_tools(:search_tool)
  end

  test "for_workspace returns workspace and global tools" do
    workspace = aven_workspaces(:one)
    tools = Aven::Agentic::Tool.for_workspace(workspace)

    assert_includes tools, aven_agentic_tools(:search_tool)
    assert_includes tools, aven_agentic_tools(:calculator_tool)
    assert_includes tools, aven_agentic_tools(:global_tool)
    assert_not_includes tools, aven_agentic_tools(:workspace_two_tool)
  end

  # Instance methods
  test "tool_class returns constantized class when exists" do
    # Create a real class for testing
    Object.const_set(:TestToolClass, Class.new(Aven::Agentic::Tools::Base)) unless defined?(TestToolClass)

    tool = Aven::Agentic::Tool.new(
      name: "test",
      class_name: "TestToolClass"
    )
    assert_equal TestToolClass, tool.tool_class
  end

  test "tool_class returns nil when class does not exist" do
    tool = Aven::Agentic::Tool.new(
      name: "test",
      class_name: "NonExistentClass"
    )
    assert_nil tool.tool_class
  end

  test "valid_class? returns false for non-existent class" do
    tool = Aven::Agentic::Tool.new(
      name: "test",
      class_name: "NonExistentClass"
    )
    assert_not tool.valid_class?
  end

  test "effective_description returns description when present" do
    tool = aven_agentic_tools(:search_tool)
    assert_equal "Search for information", tool.effective_description
  end

  test "effective_description returns default_description when description blank" do
    tool = Aven::Agentic::Tool.new(
      name: "test",
      class_name: "TestClass",
      description: nil,
      default_description: "Default description"
    )
    assert_equal "Default description", tool.effective_description
  end

  # Nested attributes
  test "accepts nested attributes for parameters" do
    tool = Aven::Agentic::Tool.new(
      workspace: aven_workspaces(:one),
      name: "new_tool",
      class_name: "NewToolClass",
      parameters_attributes: [
        { name: "param1", param_type: "string", required: true }
      ]
    )
    assert tool.valid?
    tool.save!
    assert_equal 1, tool.parameters.count
    assert_equal "param1", tool.parameters.first.name
  end

  # Destroy behavior
  test "destroying tool destroys parameters" do
    tool = aven_agentic_tools(:search_tool)
    param_ids = tool.parameters.pluck(:id)

    tool.destroy!

    param_ids.each do |id|
      assert_not Aven::Agentic::ToolParameter.exists?(id)
    end
  end

  test "destroying tool destroys agent_tools" do
    tool = aven_agentic_tools(:search_tool)
    agent_tool = aven_agentic_agent_tools(:research_agent_search)

    tool.destroy!

    assert_not Aven::Agentic::AgentTool.exists?(agent_tool.id)
  end
end
