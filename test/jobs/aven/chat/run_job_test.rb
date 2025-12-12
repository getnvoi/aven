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

  test "job calls orchestrator with thread and message" do
    orchestrator_called = false
    called_with_message = nil

    # Create a fake orchestrator
    fake_orchestrator = Object.new
    fake_orchestrator.define_singleton_method(:run) do |message|
      orchestrator_called = true
      called_with_message = message
    end

    # Stub Orchestrator.new to return our fake
    original_new = Aven::Chat::Orchestrator.method(:new)
    Aven::Chat::Orchestrator.define_singleton_method(:new) { |_thread| fake_orchestrator }

    begin
      Aven::Chat::RunJob.perform_now(@thread.id, @user_message.id)
    ensure
      Aven::Chat::Orchestrator.define_singleton_method(:new, original_new)
    end

    assert orchestrator_called, "Orchestrator.run should be called"
    assert_equal @user_message.id, called_with_message.id
  end

  test "job finds latest user message when message_id not provided" do
    orchestrator_called = false
    called_with_message = nil

    fake_orchestrator = Object.new
    fake_orchestrator.define_singleton_method(:run) do |message|
      orchestrator_called = true
      called_with_message = message
    end

    original_new = Aven::Chat::Orchestrator.method(:new)
    Aven::Chat::Orchestrator.define_singleton_method(:new) { |_thread| fake_orchestrator }

    begin
      Aven::Chat::RunJob.perform_now(@thread.id) # No message_id
    ensure
      Aven::Chat::Orchestrator.define_singleton_method(:new, original_new)
    end

    assert orchestrator_called
    # Should find the latest user message in the thread
    assert_equal "user", called_with_message.role
  end

  test "job handles orchestrator errors gracefully" do
    fake_orchestrator = Object.new
    fake_orchestrator.define_singleton_method(:run) { |_msg| raise StandardError, "LLM failed" }

    original_new = Aven::Chat::Orchestrator.method(:new)
    Aven::Chat::Orchestrator.define_singleton_method(:new) { |_thread| fake_orchestrator }

    begin
      assert_nothing_raised do
        Aven::Chat::RunJob.perform_now(@thread.id, @user_message.id)
      end
    ensure
      Aven::Chat::Orchestrator.define_singleton_method(:new, original_new)
    end
  end
end
