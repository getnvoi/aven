# frozen_string_literal: true

# This migration comes from aven (originally 20200101000022)
class CreateAvenImports < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_imports do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.string :source, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_count, default: 0
      t.integer :processed_count, default: 0
      t.integer :imported_count, default: 0
      t.integer :skipped_count, default: 0
      t.text :error_message
      t.jsonb :errors_log, default: []
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end

    add_index :aven_imports, :source
    add_index :aven_imports, :status
  end
end
