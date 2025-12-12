require "test_helper"

class Aven::WorkspaceOauthTest < ActionDispatch::IntegrationTest
  setup do
    @user = Aven::User.create!(
      email: "workspace@example.com",
      auth_tenant: "www.example.com",
      remote_id: "workspace_123"
    )

    @workspace = Aven::Workspace.create!(
      label: "Test Workspace"
    )

    Aven::WorkspaceUser.create!(
      user: @user,
      workspace: @workspace
    )
  end

  test "workspace IS set immediately after OAuth login for existing user" do
    Aven.configuration.configure_oauth(:google, {
      client_id: "test",
      client_secret: "test"
    })

    get "/aven/oauth/google"
    state = session[:oauth_state]

    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(status: 200, body: { access_token: "token" }.to_json)

    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(
        status: 200,
        body: { sub: @user.remote_id, email: @user.email, name: "Test" }.to_json
      )

    get "/aven/oauth/google/callback", params: { code: "code", state: }

    # After OAuth, BOTH session[:user_id] AND session[:workspace_id] should be set
    assert session[:user_id].present?, "User should be signed in"
    assert session[:workspace_id].present?, "Workspace SHOULD be set immediately (eager loading)"
    assert_equal @workspace.id, session[:workspace_id], "Should be set to user's existing workspace"
  end

  test "default workspace is created for new user during OAuth signup" do
    new_user = Aven::User.create!(
      email: "newuser@example.com",
      auth_tenant: "www.example.com",
      remote_id: "newuser_456"
    )

    # Verify new user has NO workspaces
    assert_equal 0, new_user.workspaces.count

    Aven.configuration.configure_oauth(:google, {
      client_id: "test",
      client_secret: "test"
    })

    get "/aven/oauth/google"
    state = session[:oauth_state]

    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(status: 200, body: { access_token: "token" }.to_json)

    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(
        status: 200,
        body: { sub: new_user.remote_id, email: new_user.email, name: "New User" }.to_json
      )

    assert_difference "Aven::Workspace.count", 1 do
      assert_difference "Aven::WorkspaceUser.count", 1 do
        get "/aven/oauth/google/callback", params: { code: "code", state: }
      end
    end

    # Verify default workspace was created
    new_user.reload
    assert_equal 1, new_user.workspaces.count
    assert_equal "Default Workspace", new_user.workspaces.first.label

    # Verify session has both user_id and workspace_id
    assert session[:user_id].present?
    assert session[:workspace_id].present?
    assert_equal new_user.workspaces.first.id, session[:workspace_id]
  end
end
