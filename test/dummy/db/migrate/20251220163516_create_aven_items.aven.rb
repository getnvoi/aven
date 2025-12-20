# frozen_string_literal: true

# This migration comes from aven (originally 20200101000009)
class CreateAvenItems < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_items do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.string :schema_slug, null: false
      t.jsonb :data, null: false, default: {}
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :aven_items, :schema_slug
    add_index :aven_items, :data, using: :gin
    add_index :aven_items, :deleted_at
  end
end
