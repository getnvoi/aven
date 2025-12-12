require "test_helper"

class Aven::Agentic::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @agent = aven_agentic_agents(:research_agent)
  end

  # Index
  test "index requires authentication" do
    get "/aven/agentic/agents"
    assert_response :redirect
  end

  test "index returns agents for workspace" do
    sign_in_as(@user)

    get "/aven/agentic/agents"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  # Show
  test "show requires authentication" do
    get "/aven/agentic/agents/#{@agent.id}"
    assert_response :redirect
  end

  test "show returns agent details" do
    sign_in_as(@user)

    get "/aven/agentic/agents/#{@agent.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @agent.id, json["id"]
    assert_equal @agent.label, json["label"]
  end

  # Create
  test "create requires authentication" do
    post "/aven/agentic/agents", params: { label: "New Agent" }
    assert_response :redirect
  end

  test "create creates new agent" do
    sign_in_as(@user)

    assert_difference "Aven::Agentic::Agent.count", 1 do
      post "/aven/agentic/agents", params: {
        agent: {
          label: "New Agent",
          system_prompt: "You are helpful"
        }
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Agent", json["label"]
  end

  test "create returns errors for invalid agent" do
    sign_in_as(@user)

    post "/aven/agentic/agents", params: { agent: { label: "" } }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].key?("label")
  end

  # Update
  test "update requires authentication" do
    patch "/aven/agentic/agents/#{@agent.id}", params: { label: "Updated" }
    assert_response :redirect
  end

  test "update updates agent" do
    sign_in_as(@user)

    patch "/aven/agentic/agents/#{@agent.id}", params: { agent: { label: "Updated Label" } }

    assert_response :success
    @agent.reload
    assert_equal "Updated Label", @agent.label
  end

  # Destroy
  test "destroy requires authentication" do
    delete "/aven/agentic/agents/#{@agent.id}"
    assert_response :redirect
  end

  test "destroy deletes agent" do
    sign_in_as(@user)

    assert_difference "Aven::Agentic::Agent.count", -1 do
      delete "/aven/agentic/agents/#{@agent.id}"
    end

    assert_response :no_content
  end

  # Workspace scoping
  test "cannot access agents from other workspaces" do
    sign_in_as(@user)

    other_agent = aven_agentic_agents(:workspace_two_agent)

    get "/aven/agentic/agents/#{other_agent.id}"
    assert_response :not_found
  end
end
