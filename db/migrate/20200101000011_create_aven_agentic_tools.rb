# frozen_string_literal: true

class CreateAvenAgenticTools < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_tools do |t|
      t.references :workspace, foreign_key: { to_table: :aven_workspaces }
      t.string :name, null: false
      t.string :class_name, null: false
      t.text :description
      t.text :default_description
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :aven_agentic_tools, [:workspace_id, :name], unique: true
    add_index :aven_agentic_tools, [:workspace_id, :class_name], unique: true
    add_index :aven_agentic_tools, :enabled
  end
end
