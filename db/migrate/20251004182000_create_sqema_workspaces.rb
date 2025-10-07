class CreateSqemaWorkspaces < ActiveRecord::Migration[8.0]
  def change
    create_table :sqema_workspaces do |t|
      t.string :label
      t.string :slug
      t.text :description
      t.string :domain

      t.timestamps
    end

    add_index :sqema_workspaces, :slug, unique: true
  end
end
