# == Schema Information
#
# Table name: aven_logs
#
#  id            :bigint           not null, primary key
#  level         :string           default("info"), not null
#  loggable_type :string           not null
#  message       :text             not null
#  metadata      :jsonb
#  state         :string
#  state_machine :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  loggable_id   :bigint           not null
#  run_id        :string
#  workspace_id  :bigint           not null
#
# Indexes
#
#  idx_aven_logs_on_loggable_run_state_created_at  (loggable_type,loggable_id,run_id,state,created_at)
#  index_aven_logs_on_created_at                   (created_at)
#  index_aven_logs_on_level                        (level)
#  index_aven_logs_on_loggable                     (loggable_type,loggable_id)
#  index_aven_logs_on_workspace_id                 (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
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
      log = Aven::Log.new(message: "test", level:, loggable: aven_workspaces(:one), workspace: aven_workspaces(:one))
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
