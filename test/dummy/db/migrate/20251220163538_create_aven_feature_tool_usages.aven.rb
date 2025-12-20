# frozen_string_literal: true

# This migration comes from aven (originally 20200101000043)
class CreateAvenFeatureToolUsages < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_feature_tool_usages do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :user, null: false, foreign_key: { to_table: :aven_users }
      t.references :feature_tool, null: false, foreign_key: { to_table: :aven_feature_tools }
      t.string :status, null: false, default: 'success'
      t.integer :duration_ms
      t.integer :http_status_code
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :aven_feature_tool_usages, [:workspace_id, :feature_tool_id, :created_at],
              name: 'idx_aven_feature_tool_usages_billing'
    add_index :aven_feature_tool_usages, :created_at, name: 'idx_aven_feature_tool_usages_time'
    add_index :aven_feature_tool_usages, [:feature_tool_id, :created_at],
              name: 'idx_aven_feature_tool_usages_tool_time'
    add_index :aven_feature_tool_usages, [:user_id, :created_at],
              name: 'idx_aven_feature_tool_usages_user_time'
    add_index :aven_feature_tool_usages, [:workspace_id, :created_at],
              name: 'idx_aven_feature_tool_usages_workspace_time'
  end
end
