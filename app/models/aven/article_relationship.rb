# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_article_relationships
#
#  id                 :bigint           not null, primary key
#  position           :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  article_id         :bigint           not null
#  related_article_id :bigint           not null
#
# Indexes
#
#  idx_article_relationships_unique                             (article_id,related_article_id) UNIQUE
#  index_aven_article_relationships_on_article_id               (article_id)
#  index_aven_article_relationships_on_article_id_and_position  (article_id,position)
#  index_aven_article_relationships_on_related_article_id       (related_article_id)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => aven_articles.id)
#  fk_rails_...  (related_article_id => aven_articles.id)
#
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
