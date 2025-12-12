require "test_helper"

class Aven::Agentic::DocumentEmbeddingJobTest < ActiveJob::TestCase
  setup do
    @document = aven_agentic_documents(:pdf_document)
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Agentic::DocumentEmbeddingJob) do
      Aven::Agentic::DocumentEmbeddingJob.perform_later(@document.id)
    end
  end

  test "job finds document" do
    skip "Requires embedding service mocking"

    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)
  end

  test "job handles non-existent document" do
    assert_nothing_raised do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(999999)
    end
  end

  test "job skips documents without OCR content" do
    doc_without_ocr = aven_agentic_documents(:image_document)

    Aven::Agentic::DocumentEmbeddingJob.perform_now(doc_without_ocr.id)

    doc_without_ocr.reload
    # Should not process - no OCR content
    assert_equal "pending", doc_without_ocr.embedding_status
  end

  test "job marks document as processing" do
    skip "Requires embedding service mocking"

    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)

    @document.reload
    # Status should transition through processing to completed
  end

  test "job creates embeddings" do
    skip "Requires embedding service mocking"

    assert_difference "Aven::Agentic::DocumentEmbedding.count" do
      Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)
    end
  end

  test "job marks document as completed on success" do
    skip "Requires embedding service mocking"

    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)

    @document.reload
    assert_equal "completed", @document.embedding_status
  end

  test "job marks document as failed on error" do
    skip "Requires embedding service mocking"

    # Would mock embedding service to raise error

    @document.reload
    assert_equal "failed", @document.embedding_status
  end

  test "job chunks content before embedding" do
    skip "Requires embedding service mocking"

    # Long content should be split into chunks
    @document.update!(ocr_content: "A" * 10000)

    Aven::Agentic::DocumentEmbeddingJob.perform_now(@document.id)

    # Should create multiple embeddings for large content
    assert @document.embeddings.count > 1
  end
end
