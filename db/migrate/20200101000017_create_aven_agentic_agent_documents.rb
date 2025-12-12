# frozen_string_literal: true

class CreateAvenAgenticAgentDocuments < ActiveRecord::Migration[8.0]
  def change
    create_table :aven_agentic_agent_documents do |t|
      t.references :agent, null: false, foreign_key: { to_table: :aven_agentic_agents }
      t.references :document, null: false, foreign_key: { to_table: :aven_agentic_documents }
      t.timestamps
    end

    add_index :aven_agentic_agent_documents, [:agent_id, :document_id], unique: true
  end
end
