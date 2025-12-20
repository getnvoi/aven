# frozen_string_literal: true

# This migration comes from aven (originally 20200101000021)
class CreateAvenItemSchemas < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_item_schemas do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.string :slug, null: false
      t.jsonb :schema, null: false, default: {}
      t.jsonb :fields, null: false, default: {}
      t.jsonb :embeds, null: false, default: {}
      t.jsonb :links, null: false, default: {}
      t.timestamps
    end

    add_index :aven_item_schemas, [:workspace_id, :slug], unique: true
    add_index :aven_item_schemas, :slug
  end
end
