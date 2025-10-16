require "test_helper"

class Aven::LogTest < ActiveSupport::TestCase
  # Associations
  test "belongs to loggable" do
    log = aven_logs(:one)
    assert_respond_to log, :loggable
  end

  test "belongs to workspace" do
    log = aven_logs(:one)
    assert_respond_to log, :workspace
  end

  # Validations
  test "validates presence of message" do
    log = Aven::Log.new(message: nil)
    assert_not log.valid?
    assert_includes log.errors[:message], "can't be blank"
  end

  test "allows valid level values" do
    valid_levels = [ "debug", "info", "warn", "error", "fatal" ]
    valid_levels.each do |level|
      log = Aven::Log.new(message: "test", level: level, loggable: aven_workspaces(:one), workspace: aven_workspaces(:one))
      assert log.valid?, "#{level} should be valid"
    end
  end

  # Callbacks
  test "applies workspace from loggable if missing" do
    workspace = aven_workspaces(:one)
    log = Aven::Log.new(
      message: "x",
      loggable: workspace,
      loggable_type: "Aven::Workspace",
      loggable_id: workspace.id
    )

    assert_nil log.workspace
    log.valid?
    assert_equal workspace, log.workspace
  end
end
