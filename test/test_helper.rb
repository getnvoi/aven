# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("dummy/db/migrate", __dir__) ]
require "rails/test_help"
require "webmock/minitest"

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Silence OmniAuth debug output
OmniAuth.config.logger = Logger.new("/dev/null")

# Load test models
require_relative "dummy/app/models/test_project"
require_relative "dummy/app/models/test_resource" if File.exist?(File.join(__dir__, "dummy/app/models/test_resource.rb"))

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

# WebMock helpers for API stubs
module APIStubHelpers
  EMBEDDING_DIMENSION = 1536

  # OpenAI Embeddings API
  def stub_openai_embeddings(vectors: nil)
    vectors ||= Array.new(EMBEDDING_DIMENSION, 0.5)

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          object: "list",
          data: [{ object: "embedding", index: 0, embedding: vectors }],
          model: "text-embedding-3-small",
          usage: { prompt_tokens: 10, total_tokens: 10 }
        }.to_json
      )
  end

  def stub_openai_embeddings_error(status: 500, message: "API error")
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: status,
        headers: { "Content-Type" => "application/json" },
        body: { error: { message: message, type: "server_error" } }.to_json
      )
  end

  # Anthropic Chat API
  def stub_anthropic_chat(content: "Test response", input_tokens: 10, output_tokens: 20)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          id: "msg_#{SecureRandom.hex(12)}",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: content }],
          model: "claude-sonnet-4-20250514",
          stop_reason: "end_turn",
          usage: { input_tokens: input_tokens, output_tokens: output_tokens }
        }.to_json
      )
  end

  def stub_anthropic_chat_error(status: 500, message: "API error")
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: status,
        headers: { "Content-Type" => "application/json" },
        body: { error: { type: "server_error", message: message } }.to_json
      )
  end

  # Stub any external API (generic)
  def stub_any_api_request
    stub_request(:any, /.*/)
  end
end

# Integration test authentication helper
module IntegrationAuthHelpers
  def sign_in_as(user, workspace = nil)
    workspace ||= user.workspace_users.first&.workspace || aven_workspaces(:one)

    post "/aven/test_sign_in", params: { user_id: user.id, workspace_id: workspace.id }

    @current_user = user
    @current_workspace = workspace
  end

  def sign_out
    delete "/aven/logout"
    @current_user = nil
    @current_workspace = nil
  end
end

class ActiveSupport::TestCase
  include APIStubHelpers

  teardown do
    WebMock.reset!
  end
end

class ActionDispatch::IntegrationTest
  include APIStubHelpers
  include IntegrationAuthHelpers
end
