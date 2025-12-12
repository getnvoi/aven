require "test_helper"

class Aven::Agentic::DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @document = aven_agentic_documents(:pdf_document)
    # Attach file to satisfy validation
    @document.file.attach(
      io: StringIO.new("fake pdf content"),
      filename: @document.filename,
      content_type: @document.content_type
    )
  end

  # Index
  test "index requires authentication" do
    get "/aven/agentic/documents"
    assert_response :redirect
  end

  test "index returns documents for workspace" do
    sign_in_as(@user)

    get "/aven/agentic/documents"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  # Show
  test "show requires authentication" do
    get "/aven/agentic/documents/#{@document.id}"
    assert_response :redirect
  end

  test "show returns document details" do
    sign_in_as(@user)

    get "/aven/agentic/documents/#{@document.id}"
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal @document.id, json["id"]
    assert_equal @document.filename, json["filename"]
  end

  # Create
  test "create requires authentication" do
    post "/aven/agentic/documents", params: {
      file: fixture_file_upload("sample.pdf", "application/pdf")
    }
    assert_response :redirect
  end

  test "create uploads document" do
    sign_in_as(@user)

    assert_difference "Aven::Agentic::Document.count", 1 do
      post "/aven/agentic/documents", params: {
        file: fixture_file_upload("sample.pdf", "application/pdf")
      }
    end

    assert_response :created
  end

  # Destroy
  test "destroy requires authentication" do
    delete "/aven/agentic/documents/#{@document.id}"
    assert_response :redirect
  end

  test "destroy deletes document" do
    sign_in_as(@user)

    assert_difference "Aven::Agentic::Document.count", -1 do
      delete "/aven/agentic/documents/#{@document.id}"
    end

    assert_response :no_content
  end

  # Workspace scoping
  test "cannot access documents from other workspaces" do
    sign_in_as(@user)

    other_doc = Aven::Agentic::Document.new(
      workspace: aven_workspaces(:two),
      filename: "other.pdf",
      content_type: "application/pdf",
      byte_size: 1024
    )
    other_doc.file.attach(
      io: StringIO.new("fake content"),
      filename: "other.pdf",
      content_type: "application/pdf"
    )
    other_doc.save!

    get "/aven/agentic/documents/#{other_doc.id}"
    assert_response :not_found
  end
end
