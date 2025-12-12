# frozen_string_literal: true

module Aven
  module Agentic
    class DynamicToolBuilder
      class << self
        # Build a RubyLLM tool from a database record
        # @param tool_record [Aven::Agentic::Tool] Database record
        # @return [Class] RubyLLM::Tool subclass
        def build(tool_record)
          return nil unless tool_record.valid_class?

          tool_class = tool_record.tool_class
          tool_description = tool_record.effective_description
          tool_parameters = tool_record.parameters.to_a
          tool_name = tool_record.name

          # Create dynamic RubyLLM tool class
          Class.new(RubyLLM::Tool) do
            @search_tool_class = tool_class
            @tool_record = tool_record
            @tool_name = tool_name

            class << self
              attr_reader :search_tool_class, :tool_record, :tool_name
            end

            description tool_description

            # Build parameters using param DSL
            tool_parameters.each do |p|
              param_name = p.name.to_sym
              param_desc = p.effective_description
              param_type = case p.param_type.to_sym
              when :integer, :float then :number
              when :array then :array
              when :boolean then :boolean
              else :string
              end

              param param_name, type: param_type, desc: param_desc, required: p.required?
            end

            # Override name instance method
            def name
              self.class.tool_name
            end

            # Execute delegates to actual tool class
            def execute(**params)
              result = self.class.search_tool_class.call(**params)
              Aven::Agentic::ToolResultFormatter.format(self.class.tool_name, result)
            end
          end
        end

        # Build all enabled tools for a workspace
        # @param workspace [Aven::Workspace, nil] Workspace to scope tools
        # @return [Array<Class>] Array of RubyLLM::Tool subclasses
        def build_all(workspace: nil)
          scope = Aven::Agentic::Tool.enabled.includes(:parameters)
          scope = scope.for_workspace(workspace) if workspace

          scope.map { |tool_record| build(tool_record) }.compact
        end

        # Get cached tool or build fresh
        def cached_build(tool_record)
          @tool_cache ||= {}
          cache_key = "#{tool_record.id}/#{tool_record.updated_at.to_f}"

          @tool_cache[cache_key] ||= build(tool_record)
        end

        def clear_cache!
          @tool_cache = {}
        end
      end
    end
  end
end
