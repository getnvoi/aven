class AddOnboardingStateAndCreatedByToAvenWorkspaces < ActiveRecord::Migration[8.0]
  def change
    add_column :aven_workspaces, :onboarding_state, :string, default: "pending"
    add_reference :aven_workspaces, :created_by, foreign_key: { to_table: :aven_users }, index: true
  end
end
