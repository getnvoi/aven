# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

# Suppress Marcel frozen string literal warnings
$VERBOSE = nil

# Disable GC during test runs for speed
GC.disable

require_relative "dummy/config/environment"

# Configure Aven schemas for tests
Aven.configure do |config|
  config.schemas = [
    Aven::Item::Schemas::Contact,
    Aven::Item::Schemas::Note,
    Aven::Item::Schemas::Company
  ]
end

# Silence ActiveRecord and Rails logging in tests
ActiveRecord::Base.logger = nil
Rails.logger.level = :fatal
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

  # Load fixtures in dependency order (item_recipients must load before invites)
  ActiveSupport::TestCase.fixtures(
    :aven_workspaces,
    :aven_workspace_roles,
    :aven_users,
    :aven_workspace_users,
    :aven_workspace_user_roles,
    :aven_sessions,
    :aven_magic_links,
    :aven_items,
    :aven_item_links,
    :aven_item_schemas,
    :aven_item_recipients,  # Must load before invites
    :aven_invites,          # Depends on item_recipients
    :aven_articles,
    :aven_article_attachments,
    :aven_article_relationships,
    :aven_logs,
    :aven_imports,
    :aven_import_entries,
    :aven_import_item_links,
    :aven_chat_threads,
    :aven_chat_messages
  )
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
        status:,
        headers: { "Content-Type" => "application/json" },
        body: { error: { message:, type: "server_error" } }.to_json
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
          usage: { input_tokens:, output_tokens: }
        }.to_json
      )
  end

  def stub_anthropic_chat_error(status: 500, message: "API error")
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status:,
        headers: { "Content-Type" => "application/json" },
        body: { error: { type: "server_error", message: } }.to_json
      )
  end

  # Stub any external API (generic)
  def stub_any_api_request
    stub_request(:any, /.*/)
  end
end

# Test authentication - injects user at controller level (no HTTP requests)
# Uses Aven::Current for thread-safe context, with fallback to thread locals
module Aven
  module TestAuthentication
    extend ActiveSupport::Concern

    included do
      prepend AuthOverrides
    end

    module AuthOverrides
      def current_user
        # Check thread-local override first (for tests), then Current
        Thread.current[:aven_test_user] || Aven::Current.user || super
      end

      def current_workspace
        # Check thread-local override first (for tests), then Current
        Thread.current[:aven_test_workspace] || Aven::Current.workspace || super
      end

      def current_session
        Thread.current[:aven_test_session] || Aven::Current.session || super
      end
    end
  end
end

# Inject test auth into controllers
Aven::ApplicationController.include(Aven::TestAuthentication)

module IntegrationAuthHelpers
  # Zero-request sign in - sets thread-local user and Current context
  def sign_in_as(user, workspace = nil)
    workspace ||= user.workspace_users.first&.workspace

    # Create a test session for the user
    session_record = user.sessions.create!(
      ip_address: "127.0.0.1",
      user_agent: "Test Agent",
      last_active_at: Time.current
    )

    # Set thread locals for backward compatibility
    Thread.current[:aven_test_user] = user
    Thread.current[:aven_test_workspace] = workspace
    Thread.current[:aven_test_session] = session_record

    # Also set Current context
    Aven::Current.session = session_record
    Aven::Current.workspace = workspace
  end

  def sign_out_test_user
    Thread.current[:aven_test_user] = nil
    Thread.current[:aven_test_workspace] = nil
    Thread.current[:aven_test_session] = nil
    Aven::Current.reset
  end

  # Full OAuth flow - use only for testing OAuth itself
  def sign_in_via_oauth(user, workspace = nil)
    workspace ||= user.workspace_users.first&.workspace

    Aven.configuration.configure_oauth(:google, {
      client_id: "test_client",
      client_secret: "test_secret"
    })

    get "/aven/oauth/google"
    stored_state = session[:oauth_state]

    stub_request(:post, "https://www.googleapis.com/oauth2/v4/token")
      .to_return(
        status: 200,
        body: { access_token: "test_token" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:get, "https://www.googleapis.com/oauth2/v3/userinfo")
      .to_return(
        status: 200,
        body: {
          sub: user.remote_id,
          email: user.email,
          name: "Test User"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get "/aven/oauth/google/callback", params: { code: "test_code", state: stored_state }
  end
end

class ActiveSupport::TestCase
  include APIStubHelpers

  # Parallelize tests
  parallelize(workers: :number_of_processors)

  teardown do
    WebMock.reset!
    Aven::Current.reset
  end
end

class ActionDispatch::IntegrationTest
  include APIStubHelpers
  include IntegrationAuthHelpers

  teardown do
    Thread.current[:aven_test_user] = nil
    Thread.current[:aven_test_workspace] = nil
    Thread.current[:aven_test_session] = nil
    Aven::Current.reset
  end
end
