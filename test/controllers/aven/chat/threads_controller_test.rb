require "test_helper"

class Aven::Chat::ThreadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @thread = aven_chat_threads(:basic_thread)
    @agent = aven_agentic_agents(:research_agent)
  end

  # Index
  test "index requires authentication" do
    get "/aven/chat/threads"
    assert_response :redirect
  end

  test "index returns threads for current user" do
    skip "Requires authentication setup"

    get "/aven/chat/threads"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "index excludes other users threads" do
    skip "Requires authentication setup"

    get "/aven/chat/threads"
    assert_response :success

    json = JSON.parse(response.body)
    thread_ids = json.map { |t| t["id"] }

    # empty_thread belongs to user two
    assert_not_includes thread_ids, aven_chat_threads(:empty_thread).id
  end

  test "index orders by recent" do
    skip "Requires authentication setup"

    get "/aven/chat/threads"
    assert_response :success

    json = JSON.parse(response.body)
    dates = json.map { |t| Time.parse(t["created_at"]) }
    assert_equal dates, dates.sort.reverse
  end

  # Show
  test "show requires authentication" do
    get "/aven/chat/threads/#{@thread.id}"
    assert_response :redirect
  end

  test "show returns thread with messages" do
    skip "Requires authentication setup"

    get "/aven/chat/threads/#{@thread.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @thread.id, json["id"]
    assert json.key?("messages")
  end

  test "show excludes other users threads" do
    skip "Requires authentication setup"

    other_thread = aven_chat_threads(:empty_thread)  # belongs to user two

    get "/aven/chat/threads/#{other_thread.id}"
    assert_response :not_found
  end

  # Create
  test "create requires authentication" do
    post "/aven/chat/threads", params: { title: "New Thread" }
    assert_response :redirect
  end

  test "create creates new thread" do
    skip "Requires authentication setup"

    assert_difference "Aven::Chat::Thread.count", 1 do
      post "/aven/chat/threads", params: {
        title: "New Thread"
      }
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "New Thread", json["title"]
  end

  test "create assigns current user" do
    skip "Requires authentication setup"

    post "/aven/chat/threads", params: { title: "New Thread" }

    json = JSON.parse(response.body)
    thread = Aven::Chat::Thread.find(json["id"])
    assert_equal @user.id, thread.user_id
  end

  test "create assigns current workspace" do
    skip "Requires authentication setup"

    post "/aven/chat/threads", params: { title: "New Thread" }

    json = JSON.parse(response.body)
    thread = Aven::Chat::Thread.find(json["id"])
    assert_equal @workspace.id, thread.workspace_id
  end

  test "create with context_markdown" do
    skip "Requires authentication setup"

    post "/aven/chat/threads", params: {
      title: "New Thread",
      context_markdown: "# Context\n\nSome markdown content"
    }

    assert_response :created
    json = JSON.parse(response.body)
    thread = Aven::Chat::Thread.find(json["id"])
    assert_equal "# Context\n\nSome markdown content", thread.context_markdown
  end

  # Ask
  test "ask requires authentication" do
    post "/aven/chat/threads/#{@thread.id}/ask", params: { question: "Hello?" }
    assert_response :redirect
  end

  test "ask creates user message" do
    skip "Requires authentication setup"

    assert_difference "@thread.messages.count", 1 do
      post "/aven/chat/threads/#{@thread.id}/ask", params: {
        question: "What is the meaning of life?"
      }
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("message")
    assert_equal "What is the meaning of life?", json["message"]["content"]
  end

  test "ask enqueues RunJob" do
    skip "Requires authentication setup"

    assert_enqueued_with(job: Aven::Chat::RunJob) do
      post "/aven/chat/threads/#{@thread.id}/ask", params: {
        question: "Hello?"
      }
    end
  end

  test "ask rejects empty question" do
    skip "Requires authentication setup"

    post "/aven/chat/threads/#{@thread.id}/ask", params: {
      question: ""
    }

    assert_response :unprocessable_entity
  end

  # Ask agent
  test "ask_agent requires authentication" do
    post "/aven/chat/threads/#{@thread.id}/ask_agent", params: {
      agent_id: @agent.id,
      question: "Help me research"
    }
    assert_response :redirect
  end

  test "ask_agent locks agent on first use" do
    skip "Requires authentication setup"

    thread = aven_chat_threads(:empty_thread)

    post "/aven/chat/threads/#{thread.id}/ask_agent", params: {
      agent_id: @agent.id,
      question: "Help me research"
    }

    thread.reload
    assert_equal @agent.id, thread.agent_id
  end

  test "ask_agent locks tools" do
    skip "Requires authentication setup"

    thread = aven_chat_threads(:empty_thread)

    post "/aven/chat/threads/#{thread.id}/ask_agent", params: {
      agent_id: @agent.id,
      question: "Help me"
    }

    thread.reload
    assert thread.tools_locked?
    assert_equal @agent.tool_names, thread.tools
  end

  test "ask_agent creates system message" do
    skip "Requires authentication setup"

    thread = aven_chat_threads(:empty_thread)

    post "/aven/chat/threads/#{thread.id}/ask_agent", params: {
      agent_id: @agent.id,
      question: "Help me"
    }

    system_message = thread.messages.where(role: :system).first
    assert_not_nil system_message
    assert_equal @agent.system_prompt, system_message.content
  end

  test "ask_agent uses agent question when none provided" do
    skip "Requires authentication setup"

    thread = aven_chat_threads(:empty_thread)

    post "/aven/chat/threads/#{thread.id}/ask_agent", params: {
      agent_id: @agent.id
    }

    user_message = thread.messages.where(role: :user).last
    assert_equal @agent.user_facing_question, user_message.content
  end

  test "ask_agent rejects agent from other workspace" do
    skip "Requires authentication setup"

    other_agent = aven_agentic_agents(:workspace_two_agent)

    post "/aven/chat/threads/#{@thread.id}/ask_agent", params: {
      agent_id: other_agent.id,
      question: "Help me"
    }

    assert_response :not_found
  end
end
