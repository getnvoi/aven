class AddDataToAvenItemLinks < ActiveRecord::Migration[8.1]
  def change
    add_column :aven_item_links, :data, :jsonb, default: {}, null: false
  end
end
