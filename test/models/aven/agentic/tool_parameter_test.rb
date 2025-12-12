# == Schema Information
#
# Table name: aven_agentic_tool_parameters
#
#  id                  :bigint           not null, primary key
#  constraints         :jsonb
#  default_description :text
#  description         :text
#  name                :string           not null
#  param_type          :string           not null
#  position            :integer          default(0), not null
#  required            :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tool_id             :bigint           not null
#
# Indexes
#
#  index_aven_agentic_tool_parameters_on_tool_id               (tool_id)
#  index_aven_agentic_tool_parameters_on_tool_id_and_name      (tool_id,name) UNIQUE
#  index_aven_agentic_tool_parameters_on_tool_id_and_position  (tool_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (tool_id => aven_agentic_tools.id)
#
require "test_helper"

class Aven::Agentic::ToolParameterTest < ActiveSupport::TestCase
  # Associations
  test "belongs to tool" do
    param = aven_agentic_tool_parameters(:search_query)
    assert_respond_to param, :tool
    assert_equal aven_agentic_tools(:search_tool), param.tool
  end

  # Validations
  test "validates presence of name" do
    param = Aven::Agentic::ToolParameter.new(
      tool: aven_agentic_tools(:search_tool),
      param_type: "string"
    )
    assert_not param.valid?
    assert_includes param.errors[:name], "can't be blank"
  end

  test "validates presence of param_type" do
    param = Aven::Agentic::ToolParameter.new(
      tool: aven_agentic_tools(:search_tool),
      name: "new_param"
    )
    assert_not param.valid?
    assert_includes param.errors[:param_type], "can't be blank"
  end

  test "validates uniqueness of name scoped to tool" do
    duplicate = Aven::Agentic::ToolParameter.new(
      tool: aven_agentic_tools(:search_tool),
      name: "query",
      param_type: "string"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "allows same param name on different tools" do
    param = Aven::Agentic::ToolParameter.new(
      tool: aven_agentic_tools(:calculator_tool),
      name: "query",
      param_type: "string"
    )
    assert param.valid?
  end

  test "validates param_type inclusion in PARAM_TYPES" do
    param = Aven::Agentic::ToolParameter.new(
      tool: aven_agentic_tools(:search_tool),
      name: "new_param",
      param_type: "invalid_type"
    )
    assert_not param.valid?
    assert_includes param.errors[:param_type], "is not included in the list"
  end

  test "valid param_types" do
    Aven::Agentic::ToolParameter::PARAM_TYPES.each do |type|
      param = Aven::Agentic::ToolParameter.new(
        tool: aven_agentic_tools(:search_tool),
        name: "test_#{type}",
        param_type: type
      )
      assert param.valid?, "Expected #{type} to be valid"
    end
  end

  # Default scope
  test "default scope orders by position" do
    tool = aven_agentic_tools(:search_tool)
    params = tool.parameters

    assert_equal "query", params.first.name
    assert_equal "limit", params.second.name
  end

  # Instance methods
  test "effective_description returns description when present" do
    param = aven_agentic_tool_parameters(:search_query)
    assert_equal "The search query", param.effective_description
  end

  test "effective_description returns default_description when description blank" do
    param = Aven::Agentic::ToolParameter.new(
      name: "test",
      param_type: "string",
      description: nil,
      default_description: "Default desc"
    )
    assert_equal "Default desc", param.effective_description
  end

  test "required? returns true when required" do
    param = aven_agentic_tool_parameters(:search_query)
    assert param.required?
  end

  test "required? returns false when not required" do
    param = aven_agentic_tool_parameters(:search_limit)
    assert_not param.required?
  end

  # Constraints
  test "constraints is a hash" do
    param = aven_agentic_tool_parameters(:search_limit)
    assert_kind_of Hash, param.constraints
  end

  test "constraints stores min/max values" do
    param = aven_agentic_tool_parameters(:search_limit)
    assert_equal 1, param.constraints["min"]
    assert_equal 100, param.constraints["max"]
  end
end
