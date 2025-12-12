# frozen_string_literal: true

require "test_helper"

class Aven::ArticleTest < ActiveSupport::TestCase
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @article = aven_articles(:published_article)
  end

  # Associations
  test "belongs to workspace" do
    assert_respond_to @article, :workspace
    assert_equal @workspace, @article.workspace
  end

  test "belongs to author (optional)" do
    assert_respond_to @article, :author
    assert_equal @user, @article.author

    # Can be nil
    article = Aven::Article.new(workspace: @workspace, title: "No Author")
    assert_nil article.author
    assert article.valid?
  end

  test "has one attached main_visual" do
    assert_respond_to @article, :main_visual
  end

  test "has many article_attachments" do
    assert_respond_to @article, :article_attachments
    assert_equal 2, @article.article_attachments.count
  end

  test "has many article_relationships" do
    assert_respond_to @article, :article_relationships
    assert_equal 2, @article.article_relationships.count
  end

  test "has many related_articles through article_relationships" do
    assert_respond_to @article, :related_articles
    related = @article.related_articles
    assert_includes related, aven_articles(:draft_article)
    assert_includes related, aven_articles(:old_published_article)
  end

  test "destroys attachments when destroyed" do
    attachment_ids = @article.article_attachments.pluck(:id)
    assert attachment_ids.any?

    @article.destroy

    attachment_ids.each do |id|
      assert_nil Aven::ArticleAttachment.find_by(id:)
    end
  end

  test "destroys relationships when destroyed" do
    relationship_ids = @article.article_relationships.pluck(:id)
    assert relationship_ids.any?

    @article.destroy

    relationship_ids.each do |id|
      assert_nil Aven::ArticleRelationship.find_by(id:)
    end
  end

  # Validations
  test "validates title presence" do
    article = Aven::Article.new(workspace: @workspace)
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end

  test "validates slug uniqueness per workspace" do
    # Create and save two articles, then try to change the second to match first's slug
    first_article = Aven::Article.create!(workspace: @workspace, title: "First Article")
    second_article = Aven::Article.create!(workspace: @workspace, title: "Second Article")

    # Now try to update second article's slug to match first's
    second_article.slug = first_article.slug
    assert_not second_article.valid?
    assert_includes second_article.errors[:slug], "has already been taken"
  end

  test "allows same slug in different workspaces" do
    other_workspace = aven_workspaces(:two)
    article = Aven::Article.new(
      workspace: other_workspace,
      title: "Same Slug OK",
      slug: @article.slug
    )
    assert article.valid?
  end

  # FriendlyId
  test "generates slug from title" do
    article = Aven::Article.create!(
      workspace: @workspace,
      title: "My New Article Title"
    )
    assert_equal "my-new-article-title", article.slug
  end

  test "can be found by slug" do
    found = @workspace.aven_articles.friendly.find(@article.slug)
    assert_equal @article, found
  end

  # Tagging
  test "responds to tag_list" do
    assert_respond_to @article, :tag_list
    assert_respond_to @article, :tag_list=
  end

  test "can set and get tags" do
    @article.tag_list = ["ruby", "rails", "testing"]
    @article.save!
    @article.reload

    assert_includes @article.tag_list, "ruby"
    assert_includes @article.tag_list, "rails"
    assert_includes @article.tag_list, "testing"
  end

  # Scopes
  test "published scope returns only published articles" do
    published = @workspace.aven_articles.published
    assert_includes published, aven_articles(:published_article)
    assert_includes published, aven_articles(:old_published_article)
    assert_not_includes published, aven_articles(:draft_article)
    assert_not_includes published, aven_articles(:scheduled_article)
  end

  test "draft scope returns only draft articles" do
    drafts = @workspace.aven_articles.draft
    assert_includes drafts, aven_articles(:draft_article)
    assert_not_includes drafts, aven_articles(:published_article)
  end

  test "scheduled scope returns only scheduled articles" do
    scheduled = @workspace.aven_articles.scheduled
    assert_includes scheduled, aven_articles(:scheduled_article)
    assert_not_includes scheduled, aven_articles(:published_article)
    assert_not_includes scheduled, aven_articles(:draft_article)
  end

  test "recent scope orders by published_at desc then created_at desc" do
    # Get only published articles (past dates) and order by recent
    articles = @workspace.aven_articles.published.recent
    # Most recently published first (published_article is 1.day.ago, old is 1.week.ago)
    assert_equal aven_articles(:published_article), articles.first
    assert_equal aven_articles(:old_published_article), articles.second
  end

  test "by_author scope filters by author" do
    by_user_one = @workspace.aven_articles.by_author(@user)
    assert by_user_one.all? { |a| a.author_id == @user.id }
  end

  # Instance methods
  test "published? returns true when published_at is in the past" do
    assert @article.published?
  end

  test "published? returns false when published_at is nil" do
    draft = aven_articles(:draft_article)
    assert_not draft.published?
  end

  test "published? returns false when published_at is in the future" do
    scheduled = aven_articles(:scheduled_article)
    assert_not scheduled.published?
  end

  test "draft? returns true when published_at is nil" do
    draft = aven_articles(:draft_article)
    assert draft.draft?
  end

  test "draft? returns false when published_at is set" do
    assert_not @article.draft?
  end

  test "scheduled? returns true when published_at is in the future" do
    scheduled = aven_articles(:scheduled_article)
    assert scheduled.scheduled?
  end

  test "scheduled? returns false when published_at is in the past" do
    assert_not @article.scheduled?
  end

  test "publish! sets published_at to now" do
    draft = aven_articles(:draft_article)
    assert_nil draft.published_at

    draft.publish!

    assert_not_nil draft.published_at
    assert draft.published_at <= Time.current
  end

  test "unpublish! sets published_at to nil" do
    assert_not_nil @article.published_at

    @article.unpublish!

    assert_nil @article.published_at
  end

  test "sorted_attachments returns attachments ordered by position" do
    attachments = @article.sorted_attachments
    positions = attachments.map(&:position)
    assert_equal positions.sort, positions
  end
end
