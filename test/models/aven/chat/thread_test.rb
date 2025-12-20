# == Schema Information
#
# Table name: aven_chat_threads
#
#  id               :bigint           not null, primary key
#  context_markdown :text
#  documents        :jsonb
#  title            :string
#  tools            :jsonb
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  index_aven_chat_threads_on_created_at                (created_at)
#  index_aven_chat_threads_on_user_id                   (user_id)
#  index_aven_chat_threads_on_workspace_id              (workspace_id)
#  index_aven_chat_threads_on_workspace_id_and_user_id  (workspace_id,user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

class Aven::Chat::ThreadTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  # Associations
  test "belongs to workspace" do
    thread = aven_chat_threads(:basic_thread)
    assert_respond_to thread, :workspace
    assert_equal aven_workspaces(:one), thread.workspace
  end

  test "belongs to user" do
    thread = aven_chat_threads(:basic_thread)
    assert_respond_to thread, :user
    assert_equal aven_users(:one), thread.user
  end

  test "has many messages" do
    thread = aven_chat_threads(:basic_thread)
    assert_respond_to thread, :messages
    assert_includes thread.messages, aven_chat_messages(:user_message)
    assert_includes thread.messages, aven_chat_messages(:assistant_message)
  end

  # TenantModel
  test "includes TenantModel concern" do
    assert Aven::Chat::Thread.include?(Aven::Model::TenantModel)
  end

  test "in_workspace scope returns threads for workspace" do
    threads = Aven::Chat::Thread.in_workspace(aven_workspaces(:one))
    assert_includes threads, aven_chat_threads(:basic_thread)
    assert_not_includes threads, aven_chat_threads(:workspace_two_thread)
  end

  # Validations
  test "validates presence of user" do
    thread = Aven::Chat::Thread.new(workspace: aven_workspaces(:one))
    assert_not thread.valid?
    assert_includes thread.errors[:user], "can't be blank"
  end

  test "valid with required attributes" do
    thread = Aven::Chat::Thread.new(
      workspace: aven_workspaces(:one),
      user: aven_users(:one)
    )
    assert thread.valid?
  end

  # Scopes
  test "recent scope orders by created_at desc" do
    threads = Aven::Chat::Thread.recent
    assert_equal threads.to_a, threads.order(created_at: :desc).to_a
  end

  # Tools locking
  test "tools_locked? returns false when tools is nil" do
    thread = aven_chat_threads(:basic_thread)
    assert_not thread.tools_locked?
  end

  test "tools_locked? returns true when tools is present" do
    thread = aven_chat_threads(:agent_thread)
    assert thread.tools_locked?
  end

  test "lock_tools! sets tools array" do
    thread = aven_chat_threads(:basic_thread)
    thread.lock_tools!(["search", "calculator"])

    assert thread.tools_locked?
    assert_equal ["search", "calculator"], thread.tools
  end

  test "lock_tools! does nothing when already locked" do
    thread = aven_chat_threads(:agent_thread)
    original_tools = thread.tools.dup

    thread.lock_tools!(["other_tool"])

    assert_equal original_tools, thread.tools
  end

  # Ask method
  test "ask creates user message" do
    thread = aven_chat_threads(:basic_thread)

    assert_difference "thread.messages.count", 1 do
      message = thread.ask("What is the weather?")

      assert_equal "user", message.role
      assert_equal "What is the weather?", message.content
      assert_equal "success", message.status
    end
  end

  test "ask enqueues RunJob" do
    thread = aven_chat_threads(:basic_thread)

    assert_enqueued_with(job: Aven::Chat::RunJob) do
      thread.ask("What is the weather?")
    end
  end

  # Usage stats
  test "usage_stats aggregates token counts" do
    thread = aven_chat_threads(:basic_thread)
    stats = thread.usage_stats

    assert_kind_of Hash, stats
    assert_respond_to stats, :[]
    assert stats.key?(:input)
    assert stats.key?(:output)
    assert stats.key?(:total)
    assert stats.key?(:cost)
  end

  # Destroy behavior
  test "destroying thread destroys messages" do
    thread = aven_chat_threads(:basic_thread)
    message_ids = thread.messages.pluck(:id)

    thread.destroy!

    message_ids.each do |id|
      assert_not Aven::Chat::Message.exists?(id)
    end
  end
end
