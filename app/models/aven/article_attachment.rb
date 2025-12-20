# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_article_attachments
#
#  id         :bigint           not null, primary key
#  position   :integer          default(0), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  article_id :bigint           not null
#
# Indexes
#
#  index_aven_article_attachments_on_article_id               (article_id)
#  index_aven_article_attachments_on_article_id_and_position  (article_id,position)
#
# Foreign Keys
#
#  fk_rails_...  (article_id => aven_articles.id)
#
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
