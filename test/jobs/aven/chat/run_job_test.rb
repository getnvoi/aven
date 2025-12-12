require "test_helper"

class Aven::Chat::RunJobTest < ActiveJob::TestCase
  setup do
    @thread = aven_chat_threads(:basic_thread)
    @user_message = aven_chat_messages(:user_message)
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Chat::RunJob) do
      Aven::Chat::RunJob.perform_later(@thread.id, @user_message.id)
    end
  end

  test "job finds thread and message" do
    skip "Requires RubyLLM mocking"

    # Would need to mock RubyLLM.chat and its chain
    Aven::Chat::RunJob.perform_now(@thread.id, @user_message.id)
  end

  test "job handles non-existent thread" do
    assert_nothing_raised do
      Aven::Chat::RunJob.perform_now(999999, @user_message.id)
    end
  end

  test "job handles non-existent message" do
    assert_nothing_raised do
      Aven::Chat::RunJob.perform_now(@thread.id, 999999)
    end
  end

  test "job creates assistant message on success" do
    skip "Requires RubyLLM mocking"

    # Mock the orchestrator
    mock_orchestrator = Minitest::Mock.new
    mock_orchestrator.expect :run, nil, [@user_message]

    Aven::Chat::Orchestrator.stub :new, mock_orchestrator do
      Aven::Chat::RunJob.perform_now(@thread.id, @user_message.id)
    end

    mock_orchestrator.verify
  end

  test "job handles errors gracefully" do
    skip "Requires RubyLLM mocking"

    # Would test error handling
  end
end
