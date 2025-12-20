# This migration comes from aven (originally 20251220092053)
class AddDataToAvenItemLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :aven_item_links, :data, :jsonb, default: {}, null: false
  end
end
