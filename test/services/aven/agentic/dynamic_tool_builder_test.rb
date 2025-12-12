require "test_helper"

class Aven::Agentic::DynamicToolBuilderTest < ActiveSupport::TestCase
  setup do
    # Define a test tool class for testing
    unless defined?(Aven::Agentic::Tools::TestSearch)
      Aven::Agentic::Tools.module_eval do
        class TestSearch < Aven::Agentic::Tools::Base
          def self.default_description
            "Test search tool"
          end

          def self.parameters
            [
              OpenStruct.new(name: "query", type: :string, description: "Search query", required: true),
              OpenStruct.new(name: "limit", type: :integer, description: "Max results", required: false)
            ]
          end

          def self.call(**params)
            { results: ["result1", "result2"], query: params[:query] }
          end
        end
      end
    end

    @tool_record = Aven::Agentic::Tool.create!(
      workspace: aven_workspaces(:one),
      name: "test_search",
      class_name: "Aven::Agentic::Tools::TestSearch",
      description: "Custom search description"
    )

    @tool_record.parameters.create!(
      name: "query",
      param_type: "string",
      description: "Search query",
      required: true,
      position: 0
    )

    @tool_record.parameters.create!(
      name: "limit",
      param_type: "integer",
      description: "Max results",
      required: false,
      position: 1
    )

    Aven::Agentic::DynamicToolBuilder.clear_cache!
  end

  teardown do
    Aven::Agentic::DynamicToolBuilder.clear_cache!
  end

  # Build method
  test "build returns nil for invalid class" do
    tool_record = Aven::Agentic::Tool.new(
      name: "invalid",
      class_name: "NonExistentClass"
    )

    result = Aven::Agentic::DynamicToolBuilder.build(tool_record)
    assert_nil result
  end

  test "build returns a class that inherits from RubyLLM::Tool" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result = Aven::Agentic::DynamicToolBuilder.build(@tool_record)
    assert result < RubyLLM::Tool
  end

  test "build creates class with correct tool_name" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result = Aven::Agentic::DynamicToolBuilder.build(@tool_record)
    assert_equal "test_search", result.tool_name
  end

  test "build creates class with search_tool_class accessor" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result = Aven::Agentic::DynamicToolBuilder.build(@tool_record)
    assert_equal Aven::Agentic::Tools::TestSearch, result.search_tool_class
  end

  # Build all
  test "build_all returns array of tool classes" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    results = Aven::Agentic::DynamicToolBuilder.build_all(workspace: aven_workspaces(:one))
    assert_kind_of Array, results
  end

  test "build_all filters by workspace" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    # Create another tool in workspace two
    Aven::Agentic::Tool.create!(
      workspace: aven_workspaces(:two),
      name: "workspace_two_test",
      class_name: "Aven::Agentic::Tools::TestSearch"
    )

    workspace_one_tools = Aven::Agentic::DynamicToolBuilder.build_all(workspace: aven_workspaces(:one))
    workspace_two_tools = Aven::Agentic::DynamicToolBuilder.build_all(workspace: aven_workspaces(:two))

    # Each workspace should have different counts
    workspace_one_names = workspace_one_tools.map(&:tool_name)
    workspace_two_names = workspace_two_tools.map(&:tool_name)

    assert_includes workspace_one_names, "test_search"
    assert_includes workspace_two_names, "workspace_two_test"
  end

  test "build_all includes global tools" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    global_tool = Aven::Agentic::Tool.create!(
      workspace: nil,
      name: "global_test_search",
      class_name: "Aven::Agentic::Tools::TestSearch"
    )

    results = Aven::Agentic::DynamicToolBuilder.build_all(workspace: aven_workspaces(:one))
    tool_names = results.map(&:tool_name)

    assert_includes tool_names, "global_test_search"
  end

  test "build_all excludes disabled tools" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    @tool_record.update!(enabled: false)

    results = Aven::Agentic::DynamicToolBuilder.build_all(workspace: aven_workspaces(:one))
    tool_names = results.map(&:tool_name)

    assert_not_includes tool_names, "test_search"
  end

  # Caching
  test "cached_build returns same instance for same tool" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result1 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)
    result2 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)

    assert_same result1, result2
  end

  test "cached_build returns new instance after tool update" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result1 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)

    @tool_record.touch
    @tool_record.reload

    result2 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)

    assert_not_same result1, result2
  end

  test "clear_cache! clears the cache" do
    skip "RubyLLM not loaded in test environment" unless defined?(RubyLLM::Tool)

    result1 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)
    Aven::Agentic::DynamicToolBuilder.clear_cache!
    result2 = Aven::Agentic::DynamicToolBuilder.cached_build(@tool_record)

    assert_not_same result1, result2
  end
end
