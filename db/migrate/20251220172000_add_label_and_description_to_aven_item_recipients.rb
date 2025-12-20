class AddLabelAndDescriptionToAvenItemRecipients < ActiveRecord::Migration[8.0]
  def change
    add_column :aven_item_recipients, :label, :string
    add_column :aven_item_recipients, :description, :text
  end
end
