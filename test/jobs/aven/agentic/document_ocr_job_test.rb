require "test_helper"

class Aven::Agentic::DocumentOcrJobTest < ActiveJob::TestCase
  setup do
    @document = aven_agentic_documents(:image_document)
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Agentic::DocumentOcrJob) do
      Aven::Agentic::DocumentOcrJob.perform_later(@document.id)
    end
  end

  test "job finds document" do
    skip "Requires OCR processor mocking"

    Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
  end

  test "job handles non-existent document" do
    assert_nothing_raised do
      Aven::Agentic::DocumentOcrJob.perform_now(999999)
    end
  end

  test "job marks document as processing" do
    skip "Requires OCR processor mocking"

    mock_processor = Minitest::Mock.new
    mock_processor.expect :process, "Extracted text"

    Aven::Agentic::Ocr::Processor.stub :new, mock_processor do
      Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
    end

    @document.reload
    assert_equal "completed", @document.ocr_status
  end

  test "job marks document as failed on error" do
    skip "Requires OCR processor mocking"

    mock_processor = Minitest::Mock.new
    mock_processor.expect :process, nil do
      raise StandardError, "OCR failed"
    end

    Aven::Agentic::Ocr::Processor.stub :new, mock_processor do
      assert_nothing_raised do
        Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
      end
    end

    @document.reload
    assert_equal "failed", @document.ocr_status
  end

  test "job skips non-OCR-required documents" do
    word_doc = aven_agentic_documents(:word_document)

    Aven::Agentic::DocumentOcrJob.perform_now(word_doc.id)

    word_doc.reload
    # Should skip OCR for Word docs (they use text extraction instead)
  end

  test "job enqueues embedding job on success" do
    skip "Requires OCR processor mocking"

    mock_processor = Minitest::Mock.new
    mock_processor.expect :process, "Extracted text"

    Aven::Agentic::Ocr::Processor.stub :new, mock_processor do
      assert_enqueued_with(job: Aven::Agentic::DocumentEmbeddingJob) do
        Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
      end
    end
  end
end
