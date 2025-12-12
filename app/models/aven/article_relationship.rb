# frozen_string_literal: true

module Aven
  class ArticleRelationship < ApplicationRecord
    self.table_name = "aven_article_relationships"

    belongs_to :article, class_name: "Aven::Article", inverse_of: :article_relationships
    belongs_to :related_article, class_name: "Aven::Article"

    validates :related_article_id, uniqueness: { scope: :article_id }
    validate :not_self_referential

    scope :ordered, -> { order(position: :asc) }

    # Delegate workspace access
    delegate :workspace, :workspace_id, to: :article

    private

      def not_self_referential
        if article_id == related_article_id
          errors.add(:related_article, "cannot be the same as the article")
        end
      end
  end
end
