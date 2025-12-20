# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_articles
#
#  id           :bigint           not null, primary key
#  description  :text
#  intro        :text
#  published_at :datetime
#  slug         :string
#  title        :string           not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  author_id    :bigint
#  workspace_id :bigint           not null
#
# Indexes
#
#  index_aven_articles_on_author_id              (author_id)
#  index_aven_articles_on_published_at           (published_at)
#  index_aven_articles_on_workspace_id           (workspace_id)
#  index_aven_articles_on_workspace_id_and_slug  (workspace_id,slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (author_id => aven_users.id)
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
module Aven
  class Article < ApplicationRecord
    self.table_name = "aven_articles"

    include Aven::Model::TenantModel

    extend FriendlyId
    friendly_id :title, use: [:slugged, :scoped], scope: :workspace

    acts_as_taggable_on :tags

    # Associations
    belongs_to :author, class_name: "Aven::User", optional: true

    has_one_attached :main_visual

    has_many :article_attachments,
             class_name: "Aven::ArticleAttachment",
             foreign_key: :article_id,
             dependent: :destroy,
             inverse_of: :article

    has_many :article_relationships,
             -> { order(position: :asc) },
             class_name: "Aven::ArticleRelationship",
             foreign_key: :article_id,
             dependent: :destroy,
             inverse_of: :article

    has_many :related_articles,
             through: :article_relationships,
             source: :related_article

    has_many :inverse_article_relationships,
             class_name: "Aven::ArticleRelationship",
             foreign_key: :related_article_id,
             dependent: :destroy

    has_many :inverse_related_articles,
             through: :inverse_article_relationships,
             source: :article

    # Nested attributes
    accepts_nested_attributes_for :article_attachments, allow_destroy: true
    accepts_nested_attributes_for :article_relationships, allow_destroy: true

    # Validations
    validates :title, presence: true
    validates :slug, uniqueness: { scope: :workspace_id }, allow_blank: true

    # Scopes
    scope :published, -> { where.not(published_at: nil).where("published_at <= ?", Time.current) }
    scope :draft, -> { where(published_at: nil) }
    scope :scheduled, -> { where.not(published_at: nil).where("published_at > ?", Time.current) }
    scope :recent, -> { order(Arel.sql("published_at DESC NULLS LAST, created_at DESC")) }
    scope :by_author, ->(user) { where(author: user) }

    # Instance methods
    def published?
      published_at.present? && published_at <= Time.current
    end

    def draft?
      published_at.nil?
    end

    def scheduled?
      published_at.present? && published_at > Time.current
    end

    def publish!
      update!(published_at: Time.current)
    end

    def unpublish!
      update!(published_at: nil)
    end

    # Returns sorted attachments
    def sorted_attachments
      article_attachments.order(position: :asc)
    end
  end
end
