# frozen_string_literal: true

module Aven
  module Searchable
    extend ActiveSupport::Concern

    included do
      include PgSearch::Model
    end

    class_methods do
      # DSL for configuring search
      #
      # @example Basic usage
      #   class Product < ApplicationRecord
      #     include Aven::Searchable
      #
      #     searchable against: [:name, :description]
      #   end
      #
      # @example With options
      #   searchable against: [:name, :description],
      #              using: { tsearch: { prefix: true, dictionary: "english" } },
      #              ranked_by: ":tsearch"
      #
      # @example With associations
      #   searchable against: [:title],
      #              associated_against: { author: :name, tags: :label }
      #
      # @example With tsvector column (for performance)
      #   searchable against: [:name, :description],
      #              using: { tsearch: { tsvector_column: "searchable" } }
      #
      def searchable(against:, **options)
        pg_search_scope(:search,
          against:,
          **options.reverse_merge(
            using: {
              tsearch: { prefix: true, negation: true }
            }
          ))

        # Convenience scope for workspace + search
        if column_names.include?("workspace_id")
          scope :search_in_workspace, ->(workspace, query) {
            where(workspace_id: workspace.id).search(query)
          }
        end
      end

      # Multi-search registration (global search across models)
      #
      # @example
      #   searchable_globally against: [:name, :description]
      #
      def searchable_globally(against:, **options)
        multisearchable against:, **options
      end
    end
  end
end
