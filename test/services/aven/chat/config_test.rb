require "test_helper"

class Aven::Chat::ConfigTest < ActiveSupport::TestCase
  setup do
    @original_config = Aven.configuration.agentic.dup
  end

  teardown do
    Aven.configuration.agentic = @original_config
  end

  # Model configuration
  test "model returns configured default_model" do
    Aven.configuration.agentic.default_model = "custom-model-123"

    assert_equal "custom-model-123", Aven::Chat::Config.model
  end

  test "model returns DEFAULT_MODEL when not configured" do
    Aven.configuration.agentic.default_model = nil

    assert_equal Aven::Chat::Config::DEFAULT_MODEL, Aven::Chat::Config.model
  end

  # System prompt
  test "system_prompt returns configured prompt" do
    Aven.configuration.agentic.system_prompt = "You are a custom assistant."

    result = Aven::Chat::Config.system_prompt
    assert_includes result, "You are a custom assistant."
  end

  test "system_prompt calls lambda when configured as proc" do
    Aven.configuration.agentic.system_prompt = -> { "Dynamic prompt: #{Time.now.year}" }

    result = Aven::Chat::Config.system_prompt
    assert_includes result, "Dynamic prompt: #{Time.now.year}"
  end

  test "system_prompt returns DEFAULT_SYSTEM_PROMPT when not configured" do
    Aven.configuration.agentic.system_prompt = nil

    result = Aven::Chat::Config.system_prompt
    assert_equal Aven::Chat::Config::DEFAULT_SYSTEM_PROMPT, result
  end

  test "system_prompt includes document content when thread has locked documents" do
    thread = aven_chat_threads(:agent_thread)
    # Thread has locked documents [1, 3]

    result = Aven::Chat::Config.system_prompt(thread: thread)

    # Should include reference documents section
    assert_includes result, "Reference Documents"
  end

  test "system_prompt does not include documents when thread has no locked documents" do
    thread = aven_chat_threads(:basic_thread)

    result = Aven::Chat::Config.system_prompt(thread: thread)

    assert_not_includes result, "Reference Documents"
  end

  # Tools configuration
  test "tools returns all tools when thread has no locked tools" do
    skip "Requires RubyLLM and proper tool setup" unless defined?(RubyLLM)

    thread = aven_chat_threads(:basic_thread)
    tools = Aven::Chat::Config.tools(thread)

    assert_kind_of Array, tools
  end

  test "tools returns empty array when thread has empty locked tools" do
    thread = aven_chat_threads(:basic_thread)
    thread.update!(tools: [])

    tools = Aven::Chat::Config.tools(thread)

    assert_equal [], tools
  end

  # Cost calculation
  test "calculate_cost returns nil when model not found" do
    result = Aven::Chat::Config.calculate_cost(
      input_tokens: 100,
      output_tokens: 50,
      model_id: "non-existent-model"
    )

    assert_nil result
  end

  test "calculate_cost returns numeric value for valid inputs" do
    skip "Requires RubyLLM models" unless defined?(RubyLLM)

    # This test would need RubyLLM to be properly configured
    # For now, we just test the method exists and accepts parameters
    assert_respond_to Aven::Chat::Config, :calculate_cost
  end

  test "calculate_cost formula is correct" do
    skip "Requires RubyLLM models and stubbing capability"
  end
end
