require "test_helper"

class Aven::Agentic::DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @workspace = aven_workspaces(:one)
    @user = aven_users(:one)
    @document = aven_agentic_documents(:pdf_document)
  end

  # Index
  test "index requires authentication" do
    get "/aven/agentic/documents"
    assert_response :redirect
  end

  test "index returns documents for workspace" do
    skip "Requires authentication setup"

    get "/aven/agentic/documents"
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
  end

  test "index paginates results" do
    skip "Requires authentication setup"

    get "/aven/agentic/documents", params: { page: 1, per_page: 10 }
    assert_response :success
  end

  # Show
  test "show requires authentication" do
    get "/aven/agentic/documents/#{@document.id}"
    assert_response :redirect
  end

  test "show returns document details" do
    skip "Requires authentication setup"

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
    skip "Requires authentication setup and file fixtures"

    assert_difference "Aven::Agentic::Document.count", 1 do
      post "/aven/agentic/documents", params: {
        file: fixture_file_upload("sample.pdf", "application/pdf")
      }
    end

    assert_response :created
  end

  test "create enqueues OCR job for PDF" do
    skip "Requires authentication setup and file fixtures"

    assert_enqueued_with(job: Aven::Agentic::DocumentOcrJob) do
      post "/aven/agentic/documents", params: {
        file: fixture_file_upload("sample.pdf", "application/pdf")
      }
    end
  end

  test "create rejects unsupported file types" do
    skip "Requires authentication setup"

    post "/aven/agentic/documents", params: {
      file: fixture_file_upload("sample.exe", "application/x-msdownload")
    }

    assert_response :unprocessable_entity
  end

  test "create rejects files too large" do
    skip "Requires authentication setup and large file fixture"

    post "/aven/agentic/documents", params: {
      file: fixture_file_upload("large_file.pdf", "application/pdf")
    }

    assert_response :unprocessable_entity
  end

  # Destroy
  test "destroy requires authentication" do
    delete "/aven/agentic/documents/#{@document.id}"
    assert_response :redirect
  end

  test "destroy deletes document" do
    skip "Requires authentication setup"

    assert_difference "Aven::Agentic::Document.count", -1 do
      delete "/aven/agentic/documents/#{@document.id}"
    end

    assert_response :no_content
  end

  test "destroy removes file attachment" do
    skip "Requires authentication setup and ActiveStorage"

    delete "/aven/agentic/documents/#{@document.id}"

    # Verify file was purged
    assert_not ActiveStorage::Blob.exists?(@document.file.blob.id)
  end

  # Workspace scoping
  test "cannot access documents from other workspaces" do
    skip "Requires authentication setup"

    # Create document in workspace two
    other_doc = Aven::Agentic::Document.create!(
      workspace: aven_workspaces(:two),
      filename: "other.pdf",
      content_type: "application/pdf",
      byte_size: 1024
    )

    get "/aven/agentic/documents/#{other_doc.id}"
    assert_response :not_found
  end
end
