# frozen_string_literal: true

require "test_helper"

class Aven::ArticleRelationshipTest < ActiveSupport::TestCase
  setup do
    @relationship = aven_article_relationships(:relationship_one)
    @article = aven_articles(:published_article)
    @related = aven_articles(:draft_article)
  end

  # Associations
  test "belongs to article" do
    assert_respond_to @relationship, :article
    assert_equal @article, @relationship.article
  end

  test "belongs to related_article" do
    assert_respond_to @relationship, :related_article
    assert_equal @related, @relationship.related_article
  end

  # Validations
  test "validates uniqueness of related_article_id scoped to article_id" do
    duplicate = Aven::ArticleRelationship.new(
      article: @article,
      related_article: @related,
      position: 99
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:related_article_id], "has already been taken"
  end

  test "prevents self-referential relationships" do
    self_ref = Aven::ArticleRelationship.new(
      article: @article,
      related_article: @article,
      position: 0
    )
    assert_not self_ref.valid?
    assert_includes self_ref.errors[:related_article], "cannot be the same as the article"
  end

  test "allows relationship to different article" do
    scheduled = aven_articles(:scheduled_article)
    relationship = Aven::ArticleRelationship.new(
      article: @article,
      related_article: scheduled,
      position: 99
    )
    assert relationship.valid?
  end

  # Scopes
  test "ordered scope orders by position asc" do
    relationships = @article.article_relationships.ordered
    positions = relationships.map(&:position)
    assert_equal positions.sort, positions
  end

  # Delegation
  test "delegates workspace to article" do
    assert_equal @article.workspace, @relationship.workspace
    assert_equal @article.workspace_id, @relationship.workspace_id
  end
end
