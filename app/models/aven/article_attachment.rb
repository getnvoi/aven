# frozen_string_literal: true

module Aven
  class ArticleAttachment < ApplicationRecord
    self.table_name = "aven_article_attachments"

    belongs_to :article, class_name: "Aven::Article", inverse_of: :article_attachments

    has_one_attached :file

    validates :position, presence: true, numericality: { greater_than_or_equal_to: 0 }

    scope :ordered, -> { order(position: :asc) }

    # Delegate workspace access
    delegate :workspace, :workspace_id, to: :article
  end
end
