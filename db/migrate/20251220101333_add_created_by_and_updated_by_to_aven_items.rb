class AddCreatedByAndUpdatedByToAvenItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :aven_items, :created_by, foreign_key: { to_table: :aven_users }, index: true
    add_reference :aven_items, :updated_by, foreign_key: { to_table: :aven_users }, index: true
  end
end
