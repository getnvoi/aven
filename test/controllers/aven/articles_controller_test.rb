# frozen_string_literal: true

require "test_helper"

class Aven::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @article = aven_articles(:published_article)
    @other_workspace_article = aven_articles(:other_workspace_article)
  end

  # Authentication
  test "index requires authentication" do
    get "/aven/articles"
    assert_response :redirect
  end

  test "show requires authentication" do
    get "/aven/articles/#{@article.id}"
    assert_response :redirect
  end

  test "new requires authentication" do
    get "/aven/articles/new"
    assert_response :redirect
  end

  test "create requires authentication" do
    post "/aven/articles", params: { article: { title: "Test" } }
    assert_response :redirect
  end

  test "edit requires authentication" do
    get "/aven/articles/#{@article.id}/edit"
    assert_response :redirect
  end

  test "update requires authentication" do
    patch "/aven/articles/#{@article.id}", params: { article: { title: "Updated" } }
    assert_response :redirect
  end

  test "destroy requires authentication" do
    delete "/aven/articles/#{@article.id}"
    assert_response :redirect
  end

  # Index
  test "index returns success" do
    sign_in_as(@user, @workspace)
    get "/aven/articles", as: :json
    assert_response :success
  end

  test "index scopes to current workspace" do
    sign_in_as(@user, @workspace)
    get "/aven/articles", as: :json
    assert_response :success
    json = JSON.parse(response.body)
    # Other workspace article should not appear in response
    assert json.none? { |a| a["id"] == @other_workspace_article.id }
  end

  # Show
  test "show returns success for workspace article" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/#{@article.id}", as: :json
    assert_response :success
  end

  test "show finds article by slug" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/#{@article.slug}", as: :json
    assert_response :success
  end

  test "show returns 404 for other workspace article" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/#{@other_workspace_article.id}", as: :json
    assert_response :not_found
  end

  # New
  test "new returns success" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/new", as: :json
    assert_response :success
  end

  # Create
  test "create creates article in workspace" do
    sign_in_as(@user, @workspace)

    assert_difference "Aven::Article.count", 1 do
      post "/aven/articles", params: {
        article: {
          title: "New Article",
          intro: "Intro text",
          description: "Full description"
        }
      }
    end

    assert_response :redirect
    article = Aven::Article.last
    assert_equal @workspace.id, article.workspace_id
  end

  test "create sets author to current user" do
    sign_in_as(@user, @workspace)

    post "/aven/articles", params: {
      article: { title: "New Article" }
    }

    article = Aven::Article.last
    assert_equal @user.id, article.author_id
  end

  test "create accepts tag_list" do
    sign_in_as(@user, @workspace)

    post "/aven/articles", params: {
      article: {
        title: "Tagged Article",
        tag_list: ["ruby", "rails"]
      }
    }

    article = Aven::Article.last
    assert_includes article.tag_list, "ruby"
    assert_includes article.tag_list, "rails"
  end

  test "create returns unprocessable_entity without title" do
    sign_in_as(@user, @workspace)

    post "/aven/articles", params: {
      article: { intro: "No title" }
    }

    assert_response :unprocessable_entity
  end

  test "create returns json on success" do
    sign_in_as(@user, @workspace)

    post "/aven/articles", params: {
      article: { title: "JSON Article" }
    }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "JSON Article", json["title"]
  end

  # Edit
  test "edit returns success for workspace article" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/#{@article.id}/edit"
    assert_response :success
  end

  test "edit returns 404 for other workspace article" do
    sign_in_as(@user, @workspace)
    get "/aven/articles/#{@other_workspace_article.id}/edit"
    assert_response :not_found
  end

  # Update
  test "update updates article attributes" do
    sign_in_as(@user, @workspace)

    patch "/aven/articles/#{@article.id}", params: {
      article: { title: "Updated Title", intro: "Updated intro" }
    }

    assert_response :redirect
    @article.reload
    assert_equal "Updated Title", @article.title
    assert_equal "Updated intro", @article.intro
  end

  test "update returns 404 for other workspace article" do
    sign_in_as(@user, @workspace)

    patch "/aven/articles/#{@other_workspace_article.id}", params: {
      article: { title: "Should Fail" }
    }

    assert_response :not_found
  end

  test "update returns json on success" do
    sign_in_as(@user, @workspace)

    patch "/aven/articles/#{@article.id}", params: {
      article: { title: "JSON Updated" }
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "JSON Updated", json["title"]
  end

  test "update returns unprocessable_entity on validation failure" do
    sign_in_as(@user, @workspace)

    patch "/aven/articles/#{@article.id}", params: {
      article: { title: "" }
    }

    assert_response :unprocessable_entity
  end

  # Destroy
  test "destroy deletes the article" do
    sign_in_as(@user, @workspace)

    assert_difference "Aven::Article.count", -1 do
      delete "/aven/articles/#{@article.id}"
    end

    assert_response :redirect
  end

  test "destroy returns 404 for other workspace article" do
    sign_in_as(@user, @workspace)

    assert_no_difference "Aven::Article.count" do
      delete "/aven/articles/#{@other_workspace_article.id}"
    end

    assert_response :not_found
  end

  test "destroy deletes associated attachments" do
    sign_in_as(@user, @workspace)
    attachment_count = @article.article_attachments.count
    assert attachment_count > 0

    assert_difference "Aven::ArticleAttachment.count", -attachment_count do
      delete "/aven/articles/#{@article.id}"
    end
  end

  test "destroy deletes associated relationships" do
    sign_in_as(@user, @workspace)
    relationship_count = @article.article_relationships.count
    assert relationship_count > 0

    assert_difference "Aven::ArticleRelationship.count", -relationship_count do
      delete "/aven/articles/#{@article.id}"
    end
  end

  test "destroy returns no_content json" do
    sign_in_as(@user, @workspace)

    delete "/aven/articles/#{@article.id}", as: :json

    assert_response :no_content
  end
end
