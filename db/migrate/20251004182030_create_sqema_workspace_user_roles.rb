class CreateSqemaWorkspaceUserRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_workspace_user_roles do |t|
      t.references :workspace_role, foreign_key: { to_table: :sqema_workspace_roles }
      t.references :workspace_user, foreign_key: { to_table: :sqema_workspace_users }

      t.timestamps
    end

    add_index :sqema_workspace_user_roles, [:workspace_role_id, :workspace_user_id], unique: true, name: "idx_sqema_ws_user_roles_on_role_user"
  end
end
