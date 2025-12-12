# frozen_string_literal: true

require "test_helper"

class Aven::ArticleAttachmentTest < ActiveSupport::TestCase
  setup do
    @attachment = aven_article_attachments(:attachment_one)
    @article = aven_articles(:published_article)
  end

  # Associations
  test "belongs to article" do
    assert_respond_to @attachment, :article
    assert_equal @article, @attachment.article
  end

  test "has one attached file" do
    assert_respond_to @attachment, :file
  end

  # Validations
  test "position defaults to zero" do
    # Position has a database default of 0
    attachment = Aven::ArticleAttachment.new(article: @article)
    assert_equal 0, attachment.position
    assert attachment.valid?
  end

  test "validates position is non-negative" do
    attachment = Aven::ArticleAttachment.new(article: @article, position: -1)
    assert_not attachment.valid?
    assert attachment.errors[:position].any?
  end

  test "allows zero position" do
    attachment = Aven::ArticleAttachment.new(article: @article, position: 0)
    assert attachment.valid?
  end

  # Scopes
  test "ordered scope orders by position asc" do
    attachments = @article.article_attachments.ordered
    positions = attachments.map(&:position)
    assert_equal positions.sort, positions
  end

  # Delegation
  test "delegates workspace to article" do
    assert_equal @article.workspace, @attachment.workspace
    assert_equal @article.workspace_id, @attachment.workspace_id
  end
end
