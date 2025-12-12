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
#  agent_id         :bigint
#  user_id          :bigint           not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  index_aven_chat_threads_on_agent_id                  (agent_id)
#  index_aven_chat_threads_on_created_at                (created_at)
#  index_aven_chat_threads_on_user_id                   (user_id)
#  index_aven_chat_threads_on_workspace_id              (workspace_id)
#  index_aven_chat_threads_on_workspace_id_and_user_id  (workspace_id,user_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => aven_agentic_agents.id)
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

  test "belongs to agent (optional)" do
    thread = aven_chat_threads(:agent_thread)
    assert_respond_to thread, :agent
    assert_equal aven_agentic_agents(:research_agent), thread.agent
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

  # Documents locking
  test "documents_locked? returns false when documents is nil" do
    thread = aven_chat_threads(:basic_thread)
    assert_not thread.documents_locked?
  end

  test "documents_locked? returns true when documents is present" do
    thread = aven_chat_threads(:agent_thread)
    assert thread.documents_locked?
  end

  test "lock_documents! sets document IDs array" do
    thread = aven_chat_threads(:basic_thread)
    thread.lock_documents!([1, 2, 3])

    assert thread.documents_locked?
    assert_equal [1, 2, 3], thread.documents
  end

  test "lock_documents! does nothing when already locked" do
    thread = aven_chat_threads(:agent_thread)
    original_docs = thread.documents.dup

    thread.lock_documents!([999])

    assert_equal original_docs, thread.documents
  end

  test "lock_documents! does nothing when document_ids blank" do
    thread = aven_chat_threads(:basic_thread)
    thread.lock_documents!([])

    assert_not thread.documents_locked?
  end

  test "locked_documents returns documents with completed OCR" do
    thread = aven_chat_threads(:agent_thread)
    docs = thread.locked_documents

    # pdf_document has OCR completed, word_document has skipped
    assert_includes docs, aven_agentic_documents(:pdf_document)
  end

  test "locked_documents returns empty when not locked" do
    thread = aven_chat_threads(:basic_thread)
    assert_empty thread.locked_documents
  end

  # Agent locking
  test "agent_locked? returns false when agent_id is nil" do
    thread = aven_chat_threads(:basic_thread)
    assert_not thread.agent_locked?
  end

  test "agent_locked? returns true when agent is set" do
    thread = aven_chat_threads(:agent_thread)
    assert thread.agent_locked?
  end

  test "lock_agent! sets agent" do
    thread = aven_chat_threads(:basic_thread)
    agent = aven_agentic_agents(:math_agent)

    thread.lock_agent!(agent)

    assert thread.agent_locked?
    assert_equal agent, thread.agent
  end

  test "lock_agent! does nothing when already locked" do
    thread = aven_chat_threads(:agent_thread)
    original_agent = thread.agent

    thread.lock_agent!(aven_agentic_agents(:math_agent))

    assert_equal original_agent, thread.agent
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

  # Ask with agent
  test "ask_with_agent locks agent on first use" do
    thread = aven_chat_threads(:basic_thread)
    agent = aven_agentic_agents(:research_agent)

    thread.ask_with_agent(agent, "Research this")

    assert thread.agent_locked?
    assert_equal agent, thread.agent
  end

  test "ask_with_agent locks tools on first use" do
    thread = aven_chat_threads(:basic_thread)
    agent = aven_agentic_agents(:research_agent)

    thread.ask_with_agent(agent, "Research this")

    assert thread.tools_locked?
    assert_equal agent.tool_names, thread.tools
  end

  test "ask_with_agent creates system message with agent prompt" do
    thread = aven_chat_threads(:basic_thread)
    agent = aven_agentic_agents(:research_agent)

    thread.ask_with_agent(agent, "Research this")

    system_messages = thread.messages.where(role: :system)
    assert_equal 1, system_messages.count
    assert_equal agent.system_prompt, system_messages.first.content
  end

  test "ask_with_agent uses agent user_facing_question when no question provided" do
    thread = aven_chat_threads(:basic_thread)
    agent = aven_agentic_agents(:research_agent)

    message = thread.ask_with_agent(agent)

    user_message = thread.messages.where(role: :user).last
    assert_equal agent.user_facing_question, user_message.content
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
