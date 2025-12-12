# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_tool_parameters
#
#  id                  :bigint           not null, primary key
#  constraints         :jsonb
#  default_description :text
#  description         :text
#  name                :string           not null
#  param_type          :string           not null
#  position            :integer          default(0), not null
#  required            :boolean          default(FALSE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  tool_id             :bigint           not null
#
# Indexes
#
#  index_aven_agentic_tool_parameters_on_tool_id               (tool_id)
#  index_aven_agentic_tool_parameters_on_tool_id_and_name      (tool_id,name) UNIQUE
#  index_aven_agentic_tool_parameters_on_tool_id_and_position  (tool_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (tool_id => aven_agentic_tools.id)
#
module Aven
  module Agentic
    class ToolParameter < Aven::ApplicationRecord
      self.table_name = "aven_agentic_tool_parameters"

      belongs_to :tool, class_name: "Aven::Agentic::Tool", inverse_of: :parameters

      validates :name, presence: true, uniqueness: { scope: :tool_id }
      validates :param_type, presence: true

      default_scope { order(:position) }

      PARAM_TYPES = %w[string integer float boolean array object].freeze

      validates :param_type, inclusion: { in: PARAM_TYPES }

      # Get effective description (user-enriched or default)
      def effective_description
        description.presence || default_description
      end

      # Check if parameter is required
      def required?
        required
      end
    end
  end
end
