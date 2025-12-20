# This migration comes from aven (originally 20200101000033)
class CreateAvenItemDocuments < ActiveRecord::Migration[7.2]
  def change
    create_table :aven_item_documents do |t|
      # References
      t.references :item, null: false, foreign_key: { to_table: :aven_items }
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.references :uploaded_by, foreign_key: { to_table: :aven_users }

      # Metadata
      t.string :label
      t.text :description
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :aven_item_documents, :metadata, using: :gin
  end
end
