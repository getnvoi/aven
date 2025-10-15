class CreateTestResources < ActiveRecord::Migration[8.0]
  def change
    create_table :test_resources do |t|
      t.string :title
      t.references :workspace, null: true, foreign_key: { to_table: :aven_workspaces }
      t.timestamps
    end
  end
end
