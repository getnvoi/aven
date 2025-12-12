# frozen_string_literal: true

module Aven
  module Agentic
    class McpController < Aven::ApplicationController
      include ActionController::Live

      skip_before_action :verify_authenticity_token
      before_action :authenticate_mcp_request

      # Single endpoint handling all MCP methods
      def handle
        case request.method
        when "POST" then handle_post
        when "GET" then handle_sse
        when "DELETE" then handle_delete
        end
      end

      # Health check endpoint
      def health
        render json: {
          status: "ok",
          server: Mcp::ServerFactory::SERVER_NAME,
          version: Mcp::ServerFactory::SERVER_VERSION,
          timestamp: Time.current.iso8601
        }
      end

      private

        def handle_post
          server = build_server
          return render_mcp_error("Server not available", -32603) unless server

          request_body = request.body.read
          Rails.logger.debug { "[Aven::MCP] Request: #{request_body}" }

          result_json = server.handle_json(request_body)

          if result_json.nil?
            return head :no_content
          end

          Rails.logger.debug { "[Aven::MCP] Response: #{result_json}" }

          result_hash = JSON.parse(result_json)
          if initialization_response?(result_hash)
            response.headers["Mcp-Session-Id"] = SecureRandom.uuid
          end

          render json: result_json, status: :ok
        rescue JSON::ParserError => e
          render_mcp_error("Parse error: #{e.message}", -32700, status: :bad_request)
        rescue => e
          Rails.logger.error { "[Aven::MCP] Error: #{e.message}" }
          render_mcp_error("Internal error", -32603, status: :internal_server_error)
        end

        def handle_sse
          response.headers["Content-Type"] = "text/event-stream"
          response.headers["Cache-Control"] = "no-cache"
          response.headers["Connection"] = "keep-alive"

          sse = ActionController::Live::SSE.new(response.stream, event: "message")
          session_id = request.headers["Mcp-Session-Id"]

          loop do
            sse.write({ type: "ping", timestamp: Time.current.iso8601 })
            sleep 30
          end
        rescue ActionController::Live::ClientDisconnected
          Rails.logger.info { "[Aven::MCP] SSE client disconnected" }
        ensure
          sse&.close
        end

        def handle_delete
          head :ok
        end

        def build_server
          Mcp::ServerFactory.build(server_context: {
            workspace: @workspace,
            api_token: @api_token
          })
        end

        def authenticate_mcp_request
          token = extract_token
          return render_mcp_error("Unauthorized", -32001, status: :unauthorized) if token.blank?

          @api_token = validate_token(token)
          render_mcp_error("Unauthorized", -32001, status: :unauthorized) unless @api_token
        end

        def extract_token
          auth_header = request.headers["Authorization"]
          return auth_header.delete_prefix("Bearer ").strip if auth_header&.start_with?("Bearer ")

          request.headers["X-Api-Key"]&.strip || params[:token]&.strip
        end

        def validate_token(token)
          env_token = ENV.fetch("AVEN_MCP_API_TOKEN", nil)
          if env_token.present? && ActiveSupport::SecurityUtils.secure_compare(token, env_token)
            OpenStruct.new(valid: true, source: :env)
          end
        end

        def render_mcp_error(message, code, status: :ok)
          render json: {
            jsonrpc: "2.0",
            error: { code:, message: },
            id: nil
          }, status:
        end

        def initialization_response?(result)
          result.dig("result", "protocolVersion").present?
        end
    end
  end
end
