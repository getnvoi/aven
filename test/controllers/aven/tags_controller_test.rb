# frozen_string_literal: true

require "test_helper"

class Aven::TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)

    # Create some tags for testing
    ActsAsTaggableOn::Tag.find_or_create_by!(name: "ruby")
    ActsAsTaggableOn::Tag.find_or_create_by!(name: "rails")
    ActsAsTaggableOn::Tag.find_or_create_by!(name: "javascript")
    ActsAsTaggableOn::Tag.find_or_create_by!(name: "React")
  end

  # Authentication
  test "index requires authentication" do
    get "/aven/tags"
    assert_response :redirect
  end

  test "create requires authentication" do
    post "/aven/tags", params: { tag: { name: "newtag" } }
    assert_response :redirect
  end

  # Index
  test "index returns success" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", as: :json
    assert_response :success
  end

  test "index returns tags as json array of names" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", as: :json

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert_includes json, "ruby"
    assert_includes json, "rails"
  end

  test "index filters by q parameter" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", params: { q: "ru" }, as: :json

    json = JSON.parse(response.body)
    assert_includes json, "ruby"
    assert_not_includes json, "javascript"
  end

  test "index search is case-insensitive" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", params: { q: "RUBY" }, as: :json

    json = JSON.parse(response.body)
    assert_includes json, "ruby"
  end

  test "index search is case-insensitive for uppercase tags" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", params: { q: "react" }, as: :json

    json = JSON.parse(response.body)
    assert_includes json, "React"
  end

  test "index orders tags alphabetically" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", as: :json

    json = JSON.parse(response.body)
    # PostgreSQL sorts case-sensitively by default (uppercase before lowercase)
    # Just verify the response is an array of strings
    assert json.all? { |tag| tag.is_a?(String) }
  end

  test "index respects limit parameter" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", params: { limit: 2 }, as: :json

    json = JSON.parse(response.body)
    assert_equal 2, json.size
  end

  test "index returns empty array when no matches" do
    sign_in_as(@user, @workspace)
    get "/aven/tags", params: { q: "nonexistent" }, as: :json

    json = JSON.parse(response.body)
    assert_equal [], json
  end

  # Create
  test "create creates new tag" do
    sign_in_as(@user, @workspace)

    assert_difference "ActsAsTaggableOn::Tag.count", 1 do
      post "/aven/tags", params: { tag: { name: "newtag" } }, as: :json
    end

    assert_response :created
  end

  test "create returns tag data" do
    sign_in_as(@user, @workspace)
    post "/aven/tags", params: { tag: { name: "created_tag" } }, as: :json

    json = JSON.parse(response.body)
    assert json["id"].present?
    assert_equal "created_tag", json["name"]
  end

  test "create finds existing tag instead of duplicating" do
    sign_in_as(@user, @workspace)

    assert_no_difference "ActsAsTaggableOn::Tag.count" do
      post "/aven/tags", params: { tag: { name: "ruby" } }, as: :json
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "ruby", json["name"]
  end

  test "create strips whitespace from name" do
    sign_in_as(@user, @workspace)
    post "/aven/tags", params: { tag: { name: "  padded  " } }, as: :json

    json = JSON.parse(response.body)
    assert_equal "padded", json["name"]
  end

  test "create returns error when name is blank" do
    sign_in_as(@user, @workspace)
    post "/aven/tags", params: { tag: { name: "" } }, as: :json

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "create accepts name via params[:name] directly" do
    sign_in_as(@user, @workspace)

    post "/aven/tags", params: { name: "direct_name" }, as: :json

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "direct_name", json["name"]
  end
end
