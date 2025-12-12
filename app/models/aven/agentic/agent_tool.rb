# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_agent_tools
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  agent_id   :bigint           not null
#  tool_id    :bigint           not null
#
# Indexes
#
#  index_aven_agentic_agent_tools_on_agent_id              (agent_id)
#  index_aven_agentic_agent_tools_on_agent_id_and_tool_id  (agent_id,tool_id) UNIQUE
#  index_aven_agentic_agent_tools_on_tool_id               (tool_id)
#
# Foreign Keys
#
#  fk_rails_...  (agent_id => aven_agentic_agents.id)
#  fk_rails_...  (tool_id => aven_agentic_tools.id)
#
module Aven
  module Agentic
    class AgentTool < Aven::ApplicationRecord
      self.table_name = "aven_agentic_agent_tools"

      belongs_to :agent, class_name: "Aven::Agentic::Agent", inverse_of: :agent_tools
      belongs_to :tool, class_name: "Aven::Agentic::Tool", inverse_of: :agent_tools

      validates :tool_id, uniqueness: { scope: :agent_id }

      delegate :workspace, :workspace_id, to: :agent
    end
  end
end
