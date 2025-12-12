# frozen_string_literal: true

class CreateAvenImportItemLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_import_item_links do |t|
      t.references :entry, null: false, foreign_key: { to_table: :aven_import_entries }
      t.references :item, null: false, foreign_key: { to_table: :aven_items }
      t.timestamps
    end

    add_index :aven_import_item_links, [:entry_id, :item_id], unique: true
  end
end
