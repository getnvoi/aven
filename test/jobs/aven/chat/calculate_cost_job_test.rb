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
    @message.update!(model: "claude-sonnet-4-20250514", input_tokens: 100, output_tokens: 50, cost_usd: nil)

    # Stub calculate_cost to return a known value
    original_method = Aven::Chat::Config.method(:calculate_cost)
    Aven::Chat::Config.define_singleton_method(:calculate_cost) do |input_tokens:, output_tokens:, model_id:|
      0.00105  # Fixed test value
    end

    begin
      Aven::Chat::CalculateCostJob.perform_now(@message.id)
    ensure
      Aven::Chat::Config.define_singleton_method(:calculate_cost, original_method)
    end

    @message.reload
    assert_in_delta 0.00105, @message.cost_usd, 0.0001
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
    @message.update!(input_tokens: 0, output_tokens: 0, cost_usd: nil)

    assert_nothing_raised do
      Aven::Chat::CalculateCostJob.perform_now(@message.id)
    end

    @message.reload
    # Cost should be 0 (0 tokens = 0 cost)
    assert_equal 0.0, @message.cost_usd.to_f
  end
end
