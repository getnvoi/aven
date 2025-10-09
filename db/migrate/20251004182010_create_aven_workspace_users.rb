class CreateAvenWorkspaceUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_workspace_users do |t|
      t.references :user, null: false, foreign_key: { to_table: :aven_users }
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }

      t.timestamps
    end

    add_index :aven_workspace_users, [:user_id, :workspace_id], unique: true, name: "idx_aven_workspace_users_on_user_workspace"
  end
end
