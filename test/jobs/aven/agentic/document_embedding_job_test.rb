require "test_helper"

class Aven::Agentic::DocumentEmbeddingJobTest < ActiveJob::TestCase
  setup do
    @document = aven_agentic_documents(:pending_embedding_document)
    # Attach a file to satisfy validation
    @document.file.attach(
      io: StringIO.new("fake PDF content"),
      filename: @document.filename,
      content_type: @document.content_type
    )
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Agentic::DocumentEmbeddingJob) do
      Aven::Agentic::DocumentEmbeddingJob.perform_later(@document.id)
    end
  end

  test "job processes document with OCR content" do
    assert_difference "Aven::Agentic::DocumentEmbedding.count" do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)
    end

    @document.reload
    assert_equal "completed", @document.embedding_status
  end

  test "job handles non-existent document" do
    assert_nothing_raised do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(999999)
    end
  end

  test "job skips documents without OCR content" do
    doc_without_ocr = aven_agentic_documents(:image_document)

    assert_no_difference "Aven::Agentic::DocumentEmbedding.count" do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(doc_without_ocr.id)
    end

    doc_without_ocr.reload
    assert_equal "pending", doc_without_ocr.embedding_status
  end

  test "job skips documents not in pending status" do
    completed_doc = aven_agentic_documents(:pdf_document)
    assert_equal "completed", completed_doc.embedding_status

    assert_no_difference "Aven::Agentic::DocumentEmbedding.count" do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(completed_doc.id)
    end
  end

  test "job marks document as completed on success" do
    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)

    @document.reload
    assert_equal "completed", @document.embedding_status
  end

  test "job creates embeddings for document chunks" do
    # Long content should be split into chunks
    @document.update!(ocr_content: "A" * 2500)

    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)

    # With chunk_size=1000 and overlap=200, 2500 chars should create ~3 chunks
    assert @document.embeddings.count >= 2, "Should create multiple chunks for large content"
  end
end
