# frozen_string_literal: true

class CreateAvenAgenticAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_agents do |t|
      t.references :workspace, null: false, foreign_key: { to_table: :aven_workspaces }
      t.string :label, null: false
      t.string :slug
      t.text :system_prompt
      t.text :user_facing_question
      t.boolean :enabled, default: true, null: false
      t.timestamps
    end

    add_index :aven_agentic_agents, [:workspace_id, :slug], unique: true
    add_index :aven_agentic_agents, :enabled
  end
end
