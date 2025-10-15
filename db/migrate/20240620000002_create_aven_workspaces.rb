class CreateAvenWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_workspaces do |t|
      t.string :label
      t.string :slug
      t.text :description
      t.string :domain

      t.timestamps
    end

    add_index :aven_workspaces, :slug, unique: true
  end
end
