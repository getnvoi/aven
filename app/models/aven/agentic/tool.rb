# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_tools
#
#  id                  :bigint           not null, primary key
#  class_name          :string           not null
#  default_description :text
#  description         :text
#  enabled             :boolean          default(TRUE), not null
#  name                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  workspace_id        :bigint
#
# Indexes
#
#  index_aven_agentic_tools_on_enabled                      (enabled)
#  index_aven_agentic_tools_on_workspace_id                 (workspace_id)
#  index_aven_agentic_tools_on_workspace_id_and_class_name  (workspace_id,class_name) UNIQUE
#  index_aven_agentic_tools_on_workspace_id_and_name        (workspace_id,name) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  module Agentic
    class Tool < Aven::ApplicationRecord
      self.table_name = "aven_agentic_tools"

      belongs_to :workspace, class_name: "Aven::Workspace", optional: true

      has_many :parameters,
               class_name: "Aven::Agentic::ToolParameter",
               foreign_key: :tool_id,
               dependent: :destroy,
               inverse_of: :tool

      has_many :agent_tools,
               class_name: "Aven::Agentic::AgentTool",
               foreign_key: :tool_id,
               dependent: :destroy,
               inverse_of: :tool

      has_many :agents, through: :agent_tools

      accepts_nested_attributes_for :parameters, allow_destroy: true

      validates :name, presence: true, uniqueness: { scope: :workspace_id }
      validates :class_name, presence: true, uniqueness: { scope: :workspace_id }

      scope :enabled, -> { where(enabled: true) }
      scope :global, -> { where(workspace_id: nil) }
      scope :for_workspace, ->(workspace) {
        where(workspace_id: [nil, workspace.id])
      }

      # Get the actual tool class
      def tool_class
        class_name.constantize
      rescue NameError
        nil
      end

      # Check if tool class exists and is valid
      def valid_class?
        klass = tool_class
        klass.present? && klass < Aven::Agentic::Tools::Base
      end

      # Get effective description (user-enriched or default)
      def effective_description
        description.presence || default_description
      end

      # Sync from code definition
      def sync_from_code!
        klass = tool_class
        return false unless klass

        self.default_description = klass.default_description

        code_params = klass.parameters
        code_names = code_params.map { |p| p.name.to_s }

        # Remove deleted parameters
        parameters.where.not(name: code_names).destroy_all

        # Create or update parameters
        code_params.each_with_index do |param_def, index|
          param = parameters.find_or_initialize_by(name: param_def.name.to_s)
          param.param_type = param_def.type.to_s
          param.default_description = param_def.description
          param.required = param_def.required || false
          param.constraints = param_def.constraints || {}
          param.position = index
          param.save!
        end

        save!
      end
    end
  end
end
