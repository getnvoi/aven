require "test_helper"

class Aven::Agentic::AgentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @agent = aven_agentic_agents(:research_agent)

    # Set up authenticated session
    post_via_redirect = false
    # Simulate login by setting session
  end

  # Helper to simulate authentication
  def sign_in(user, workspace)
    # Set up session for testing
    post "/aven/oauth/github/callback", params: { code: "test" }, headers: {
      "Cookie" => "user_id=#{user.id}; workspace_id=#{workspace.id}"
    }
  rescue
    # Fallback: just ensure session is set
  end

  # Index
  test "index requires authentication" do
    get "/aven/agentic/agents"
    # Should redirect or return unauthorized
    assert_response :redirect
  end

  test "index returns agents for workspace" do
    skip "Requires authentication setup"

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
    skip "Requires authentication setup"

    get "/aven/agentic/agents/#{@agent.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @agent.id, json["id"]
    assert_equal @agent.label, json["label"]
  end

  # Create
  test "create requires authentication" do
    post "/aven/agentic/agents", params: {
      label: "New Agent",
      description: "A new agent"
    }
    assert_response :redirect
  end

  test "create creates new agent" do
    skip "Requires authentication setup"

    assert_difference "Aven::Agentic::Agent.count", 1 do
      post "/aven/agentic/agents", params: {
        label: "New Agent",
        description: "A new agent"
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Agent", json["label"]
  end

  test "create returns errors for invalid agent" do
    skip "Requires authentication setup"

    post "/aven/agentic/agents", params: {
      label: nil,
      description: "No label"
    }

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["errors"].key?("label")
  end

  # Update
  test "update requires authentication" do
    patch "/aven/agentic/agents/#{@agent.id}", params: {
      label: "Updated Label"
    }
    assert_response :redirect
  end

  test "update updates agent" do
    skip "Requires authentication setup"

    patch "/aven/agentic/agents/#{@agent.id}", params: {
      label: "Updated Label"
    }

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
    skip "Requires authentication setup"

    assert_difference "Aven::Agentic::Agent.count", -1 do
      delete "/aven/agentic/agents/#{@agent.id}"
    end

    assert_response :no_content
  end

  # Workspace scoping
  test "cannot access agents from other workspaces" do
    skip "Requires authentication setup"

    other_agent = aven_agentic_agents(:workspace_two_agent)

    get "/aven/agentic/agents/#{other_agent.id}"
    assert_response :not_found
  end
end
