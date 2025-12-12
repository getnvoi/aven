# frozen_string_literal: true

class CreateAvenImportEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_import_entries do |t|
      t.references :import, null: false, foreign_key: { to_table: :aven_imports }
      t.jsonb :data, null: false, default: {}
      t.timestamps
    end

    add_index :aven_import_entries, :data, using: :gin
  end
end
