# frozen_string_literal: true

class CreateAvenAgenticAgentTools < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_agent_tools do |t|
      t.references :agent, null: false, foreign_key: { to_table: :aven_agentic_agents }
      t.references :tool, null: false, foreign_key: { to_table: :aven_agentic_tools }
      t.timestamps
    end

    add_index :aven_agentic_agent_tools, [:agent_id, :tool_id], unique: true
  end
end
