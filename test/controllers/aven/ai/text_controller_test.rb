# frozen_string_literal: true

require "test_helper"
require "ostruct"

class Aven::Ai::TextControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
  end

  # Authentication
  test "generate requires authentication" do
    post "/aven/ai/text/generate", params: { prompt: "Hello" }
    assert_response :redirect
  end

  # Note: Testing SSE streaming with ActionController::Live is complex
  # These tests verify the controller setup and mock the RubyLLM calls

  # Helper to create a mock chat object
  def mock_chat_object(response_content: "Test response", &config_block)
    chat = Object.new
    chat.define_singleton_method(:with_instructions) { |_| self }
    chat.define_singleton_method(:ask) do |_prompt, &block|
      block&.call(OpenStruct.new(content: response_content))
    end
    chat
  end

  test "generate returns success with mocked RubyLLM" do
    sign_in_as(@user, @workspace)

    mock_chat = mock_chat_object(response_content: "Test response")

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_response :success
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate sets correct content type header" do
    sign_in_as(@user, @workspace)

    mock_chat = mock_chat_object
    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_equal "text/event-stream", response.headers["Content-Type"]
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate sets cache control header" do
    sign_in_as(@user, @workspace)

    mock_chat = mock_chat_object
    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_equal "no-cache", response.headers["Cache-Control"]
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate uses default model when not specified" do
    sign_in_as(@user, @workspace)

    received_model = nil
    mock_chat = mock_chat_object

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) do |model:, **_opts|
      received_model = model
      mock_chat
    end

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_equal "gpt-4o-mini", received_model
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate accepts custom model parameter" do
    sign_in_as(@user, @workspace)

    received_model = nil
    mock_chat = mock_chat_object

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) do |model:, **_opts|
      received_model = model
      mock_chat
    end

    begin
      post "/aven/ai/text/generate", params: {
        prompt: "Hello",
        model: "gpt-4"
      }
      assert_equal "gpt-4", received_model
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate applies system_prompts" do
    sign_in_as(@user, @workspace)

    prompts_received = []
    mock_chat = Object.new
    mock_chat.define_singleton_method(:with_instructions) do |prompt|
      prompts_received << prompt
      self
    end
    mock_chat.define_singleton_method(:ask) { |_prompt, &block| }

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: {
        prompt: "Hello",
        system_prompts: ["Be helpful", "Be concise"]
      }
      assert_includes prompts_received, "Be helpful"
      assert_includes prompts_received, "Be concise"
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate streams response in SSE format" do
    sign_in_as(@user, @workspace)

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) do |_prompt, &block|
      block.call(OpenStruct.new(content: "Hello"))
      block.call(OpenStruct.new(content: " World"))
    end

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_response :success
      assert_includes response.body, "data:"
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate sends DONE at end" do
    sign_in_as(@user, @workspace)

    mock_chat = Object.new
    mock_chat.define_singleton_method(:ask) do |_prompt, &block|
      block.call(OpenStruct.new(content: "Response"))
    end

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| mock_chat }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_includes response.body, "data: [DONE]"
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end

  test "generate handles errors gracefully" do
    sign_in_as(@user, @workspace)

    original_method = RubyLLM.method(:chat)
    RubyLLM.define_singleton_method(:chat) { |**_opts| raise StandardError, "API Error" }

    begin
      post "/aven/ai/text/generate", params: { prompt: "Hello" }
      assert_response :success # Still returns 200 with SSE
      assert_includes response.body, "error"
    ensure
      RubyLLM.define_singleton_method(:chat, original_method)
    end
  end
end
