# frozen_string_literal: true

# This migration comes from aven (originally 20200101000042)
class CreateAvenFeatureWorkspaceUsers < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_feature_workspace_users do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :user, null: false, foreign_key: { to_table: :aven_users }
      t.references :feature, null: false, foreign_key: { to_table: :aven_features }
      t.boolean :enabled, default: false, null: false
      t.jsonb :config, default: {}

      t.timestamps
    end

    add_index :aven_feature_workspace_users, [:workspace_id, :user_id, :feature_id],
              unique: true,
              name: 'idx_aven_feature_workspace_users_unique'
  end
end
