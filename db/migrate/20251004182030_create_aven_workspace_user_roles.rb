class CreateAvenWorkspaceUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_workspace_user_roles do |t|
      t.references :workspace_role, foreign_key: { to_table: :aven_workspace_roles }
      t.references :workspace_user, foreign_key: { to_table: :aven_workspace_users }

      t.timestamps
    end

    add_index :aven_workspace_user_roles, [:workspace_role_id, :workspace_user_id], unique: true, name: "idx_aven_ws_user_roles_on_role_user"
  end
end
