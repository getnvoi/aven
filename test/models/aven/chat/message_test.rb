# == Schema Information
#
# Table name: aven_chat_messages
#
#  id            :bigint           not null, primary key
#  completed_at  :datetime
#  content       :text
#  cost_usd      :decimal(10, 6)   default(0.0)
#  input_tokens  :integer          default(0)
#  model         :string
#  output_tokens :integer          default(0)
#  role          :string           not null
#  started_at    :datetime
#  status        :string           default("pending")
#  tool_call     :jsonb
#  total_tokens  :integer          default(0)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  parent_id     :bigint
#  thread_id     :bigint           not null
#
# Indexes
#
#  index_aven_chat_messages_on_parent_id                 (parent_id)
#  index_aven_chat_messages_on_role                      (role)
#  index_aven_chat_messages_on_status                    (status)
#  index_aven_chat_messages_on_thread_id                 (thread_id)
#  index_aven_chat_messages_on_thread_id_and_created_at  (thread_id,created_at)
#
# Foreign Keys
#
#  fk_rails_...  (parent_id => aven_chat_messages.id)
#  fk_rails_...  (thread_id => aven_chat_threads.id)
#
require "test_helper"

class Aven::Chat::MessageTest < ActiveSupport::TestCase
  # Associations
  test "belongs to thread" do
    message = aven_chat_messages(:user_message)
    assert_respond_to message, :thread
    assert_equal aven_chat_threads(:basic_thread), message.thread
  end

  test "belongs to parent (optional)" do
    message = aven_chat_messages(:assistant_message)
    assert_respond_to message, :parent
    assert_equal aven_chat_messages(:user_message), message.parent
  end

  test "has many replies" do
    message = aven_chat_messages(:user_message)
    assert_respond_to message, :replies
    assert_includes message.replies, aven_chat_messages(:assistant_message)
  end

  # Enums
  test "role enum includes expected values" do
    assert Aven::Chat::Message.roles.key?("user")
    assert Aven::Chat::Message.roles.key?("assistant")
    assert Aven::Chat::Message.roles.key?("tool")
    assert Aven::Chat::Message.roles.key?("system")
  end

  test "status enum includes expected values" do
    assert Aven::Chat::Message.statuses.key?("pending")
    assert Aven::Chat::Message.statuses.key?("streaming")
    assert Aven::Chat::Message.statuses.key?("success")
    assert Aven::Chat::Message.statuses.key?("error")
  end

  test "role enum has prefix" do
    message = aven_chat_messages(:user_message)
    assert message.role_user?
    assert_not message.role_assistant?
  end

  test "status enum has prefix" do
    message = aven_chat_messages(:user_message)
    assert message.status_success?
    assert_not message.status_pending?
  end

  # Validations
  test "validates presence of thread" do
    message = Aven::Chat::Message.new(role: :user, content: "Hello")
    assert_not message.valid?
    assert_includes message.errors[:thread], "must exist"
  end

  test "validates presence of role" do
    message = Aven::Chat::Message.new(
      thread: aven_chat_threads(:basic_thread),
      content: "Hello"
    )
    assert_not message.valid?
    assert_includes message.errors[:role], "can't be blank"
  end

  test "validates presence of content for non-pending assistant" do
    message = Aven::Chat::Message.new(
      thread: aven_chat_threads(:basic_thread),
      role: :assistant,
      status: :success,
      content: nil
    )
    assert_not message.valid?
    assert_includes message.errors[:content], "can't be blank"
  end

  test "allows blank content for pending assistant" do
    message = Aven::Chat::Message.new(
      thread: aven_chat_threads(:basic_thread),
      role: :assistant,
      status: :pending,
      content: nil
    )
    assert message.valid?
  end

  test "valid user message" do
    message = Aven::Chat::Message.new(
      thread: aven_chat_threads(:basic_thread),
      role: :user,
      content: "Hello"
    )
    assert message.valid?
  end

  # Scopes
  test "by_tool_call_id finds message by tool call ID" do
    tool_message = aven_chat_messages(:tool_message)
    found = Aven::Chat::Message.by_tool_call_id("call_123")

    assert_includes found, tool_message
  end

  test "chronological orders by created_at asc" do
    messages = Aven::Chat::Message.chronological
    assert_equal messages.to_a, messages.order(:created_at).to_a
  end

  # Instance methods
  test "duration returns nil when timing not available" do
    message = aven_chat_messages(:user_message)
    assert_nil message.duration
  end

  test "duration returns difference between completed_at and started_at" do
    message = aven_chat_messages(:assistant_message)
    assert_not_nil message.duration
    assert_kind_of Numeric, message.duration
  end

  test "mark_started! updates status and started_at" do
    message = aven_chat_messages(:pending_assistant)
    message.mark_started!

    assert_equal "streaming", message.status
    assert_not_nil message.started_at
  end

  test "mark_completed! updates all fields" do
    message = aven_chat_messages(:pending_assistant)
    message.mark_started!
    message.mark_completed!(
      content: "Response content",
      model: "claude-3",
      tokens: { input: 100, output: 50, total: 150 }
    )

    assert_equal "success", message.status
    assert_equal "Response content", message.content
    assert_equal "claude-3", message.model
    assert_equal 100, message.input_tokens
    assert_equal 50, message.output_tokens
    assert_equal 150, message.total_tokens
    assert_not_nil message.completed_at
  end

  test "mark_failed! updates status and content" do
    message = aven_chat_messages(:pending_assistant)
    message.mark_started!
    message.mark_failed!("Something went wrong")

    assert_equal "error", message.status
    assert_equal "Something went wrong", message.content
    assert_not_nil message.completed_at
  end

  test "append_content! adds to existing content" do
    message = aven_chat_messages(:streaming_message)
    original_content = message.content.dup

    message.append_content!(" more text")

    assert_equal original_content + " more text", message.content
  end

  test "append_content! handles nil content" do
    message = aven_chat_messages(:pending_assistant)
    message.update_column(:content, nil)

    message.append_content!("first chunk")

    assert_equal "first chunk", message.content
  end

  # Tool call
  test "tool_call is a hash" do
    message = aven_chat_messages(:tool_message)
    assert_kind_of Hash, message.tool_call
  end

  test "tool_call contains expected keys" do
    message = aven_chat_messages(:tool_message)
    assert message.tool_call.key?("id")
    assert message.tool_call.key?("name")
    assert message.tool_call.key?("arguments")
    assert message.tool_call.key?("status")
  end

  # Token tracking
  test "tokens default to zero" do
    message = Aven::Chat::Message.new(
      thread: aven_chat_threads(:basic_thread),
      role: :user,
      content: "Hello"
    )
    message.save!

    assert_equal 0, message.input_tokens
    assert_equal 0, message.output_tokens
    assert_equal 0, message.total_tokens
  end

  # Destroy behavior
  test "destroying parent nullifies child parent_id" do
    parent = aven_chat_messages(:user_message)
    child = aven_chat_messages(:assistant_message)

    parent.destroy!
    child.reload

    assert_nil child.parent_id
  end
end
