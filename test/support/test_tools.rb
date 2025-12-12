# frozen_string_literal: true

# Test tool stubs that simulate what client applications would provide
# These are used by fixtures and tests to verify the engine's tool infrastructure

module Aven
  module Agentic
    module Tools
      class Search < Base
        def self.default_description
          "Search for information"
        end

        param :query, type: :string, desc: "Search query", required: true
        param :limit, type: :integer, desc: "Max results", required: false

        def self.call(query:, limit: 10, **_params)
          { results: [], query:, limit: }
        end
      end

      class Calculator < Base
        def self.default_description
          "Perform math calculations"
        end

        param :expression, type: :string, desc: "Math expression", required: true

        def self.call(expression:, **_params)
          { result: "42", expression: }
        end
      end

      class GlobalSearch < Base
        def self.default_description
          "Global search across all workspaces"
        end

        param :query, type: :string, desc: "Search query", required: true

        def self.call(query:, **_params)
          { results: [], query: }
        end
      end

      class Disabled < Base
        def self.default_description
          "A disabled tool for testing"
        end

        def self.call(**_params)
          { status: "disabled" }
        end
      end

      # Used by DynamicToolBuilder tests
      class TestSearch < Base
        def self.default_description
          "Test search tool"
        end

        param :query, type: :string, desc: "Search query", required: true
        param :limit, type: :integer, desc: "Max results", required: false

        def self.call(query:, limit: 10, **_params)
          { results: ["result1", "result2"], query:, limit: }
        end
      end
    end
  end
end
