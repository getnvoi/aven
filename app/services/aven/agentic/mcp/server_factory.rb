# frozen_string_literal: true

module Aven
  module Agentic
    module Mcp
      class ServerFactory
        SERVER_NAME = "aven-mcp-server"
        SERVER_VERSION = Aven::VERSION

        class << self
          # Build an MCP server instance
          # @param server_context [Hash] Context data for the server
          # @return [MCP::Server] Configured MCP server
          def build(server_context: {})
            return nil unless defined?(::MCP::Server)

            server = ::MCP::Server.new(
              name: SERVER_NAME,
              version: SERVER_VERSION
            )

            # Register tools
            register_tools(server, server_context)

            server
          end

          private

            def register_tools(server, context)
              workspace = context[:workspace]
              tools = Aven::Agentic::DynamicToolBuilder.build_all(workspace:)

              tools.each do |tool_class|
                adapter = Adapter.new(tool_class, context)
                server.register_tool(adapter.to_mcp_tool)
              end
            end
        end
      end
    end
  end
end
