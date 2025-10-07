class CreateSqemaWorkspaceUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_workspace_users do |t|
      t.references :user, null: false, foreign_key: { to_table: :sqema_users }
      t.references :workspace, null: false, foreign_key: { to_table: :sqema_workspaces }

      t.timestamps
    end

    add_index :sqema_workspace_users, [:user_id, :workspace_id], unique: true, name: "idx_sqema_workspace_users_on_user_workspace"
  end
end
