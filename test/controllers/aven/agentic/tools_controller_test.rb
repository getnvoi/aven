require "test_helper"

class Aven::Agentic::ToolsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @tool = aven_agentic_tools(:search_tool)
  end

  # Index
  test "index requires authentication" do
    get "/aven/agentic/tools"
    assert_response :redirect
  end

  test "index returns tools for workspace" do
    sign_in_as(@user)

    get "/aven/agentic/tools"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "index includes global tools" do
    sign_in_as(@user)

    get "/aven/agentic/tools"
    assert_response :success

    json = JSON.parse(response.body)
    tool_names = json.map { |t| t["name"] }

    assert_includes tool_names, "global_search"
  end

  # Show
  test "show requires authentication" do
    get "/aven/agentic/tools/#{@tool.id}"
    assert_response :redirect
  end

  test "show returns tool details with parameters" do
    sign_in_as(@user)

    get "/aven/agentic/tools/#{@tool.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @tool.id, json["id"]
    assert_equal @tool.name, json["name"]
    assert json.key?("parameters")
  end

  # Update
  test "update requires authentication" do
    patch "/aven/agentic/tools/#{@tool.id}", params: {
      tool: { description: "Updated description" }
    }
    assert_response :redirect
  end

  test "update updates tool description" do
    sign_in_as(@user)

    patch "/aven/agentic/tools/#{@tool.id}", params: {
      tool: { description: "Updated description" }
    }

    assert_response :success
    @tool.reload
    assert_equal "Updated description", @tool.description
  end

  test "update can enable/disable tool" do
    sign_in_as(@user)

    patch "/aven/agentic/tools/#{@tool.id}", params: {
      tool: { enabled: false }
    }

    assert_response :success
    @tool.reload
    assert_not @tool.enabled
  end

  # Workspace scoping
  test "cannot access tools from other workspaces" do
    sign_in_as(@user)

    other_tool = aven_agentic_tools(:workspace_two_tool)

    get "/aven/agentic/tools/#{other_tool.id}"
    assert_response :not_found
  end

  test "can access global tools" do
    sign_in_as(@user)

    global_tool = aven_agentic_tools(:global_tool)

    get "/aven/agentic/tools/#{global_tool.id}"
    assert_response :success
  end
end
