class CreateTestProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :test_projects do |t|
      t.string :name
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.timestamps
    end
  end
end
