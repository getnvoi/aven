# frozen_string_literal: true

# This migration comes from aven (originally 20200101000010)
class CreateAvenItemLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_item_links do |t|
      t.references :source, null: false, foreign_key: { to_table: :aven_items }
      t.references :target, null: false, foreign_key: { to_table: :aven_items }
      t.string :relation, null: false
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :aven_item_links, [:source_id, :relation]
    add_index :aven_item_links, [:target_id, :relation]
    add_index :aven_item_links, [:source_id, :target_id, :relation], unique: true
  end
end
