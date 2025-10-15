class CreateAvenWorkspaceRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_workspace_roles do |t|
      t.references :workspace, foreign_key: { to_table: :aven_workspaces }
      t.string :label, null: false
      t.string :description

      t.timestamps
    end

    add_index :aven_workspace_roles, [ :workspace_id, :label ], unique: true, name: "idx_aven_workspace_roles_on_ws_label"
  end
end
