require "test_helper"

class Aven::Chat::CalculateCostJobTest < ActiveJob::TestCase
  setup do
    @message = aven_chat_messages(:assistant_message)
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Chat::CalculateCostJob) do
      Aven::Chat::CalculateCostJob.perform_later(@message.id)
    end
  end

  test "job finds message and calculates cost" do
    skip "Requires RubyLLM models setup"

    Aven::Chat::CalculateCostJob.perform_now(@message.id)

    @message.reload
    # Cost would be calculated based on token counts
  end

  test "job handles non-existent message" do
    assert_nothing_raised do
      Aven::Chat::CalculateCostJob.perform_now(999999)
    end
  end

  test "job skips messages without model" do
    message = aven_chat_messages(:user_message)  # No model set

    assert_nothing_raised do
      Aven::Chat::CalculateCostJob.perform_now(message.id)
    end
  end

  test "job skips messages without tokens" do
    @message.update!(input_tokens: 0, output_tokens: 0)

    Aven::Chat::CalculateCostJob.perform_now(@message.id)

    @message.reload
    # Cost should remain nil or 0
  end
end
