require "test_helper"

class Aven::Agentic::DocumentOcrJobTest < ActiveJob::TestCase
  setup do
    @document = aven_agentic_documents(:image_document)
    # Attach a file to satisfy validation
    @document.file.attach(
      io: StringIO.new("fake image content"),
      filename: @document.filename,
      content_type: @document.content_type
    )
  end

  test "job is enqueued" do
    assert_enqueued_with(job: Aven::Agentic::DocumentOcrJob) do
      Aven::Agentic::DocumentOcrJob.perform_later(@document.id)
    end
  end

  test "job handles non-existent document" do
    assert_nothing_raised do
      Aven::Agentic::DocumentOcrJob.perform_now(999999)
    end
  end

  test "job processes document and marks completed" do
    # Stub the class method
    original_method = Aven::Agentic::Ocr::Processor.method(:process)
    Aven::Agentic::Ocr::Processor.define_singleton_method(:process) { |_doc| "Extracted text content" }

    begin
      Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
    ensure
      Aven::Agentic::Ocr::Processor.define_singleton_method(:process, original_method)
    end

    @document.reload
    assert_equal "completed", @document.ocr_status
    assert_equal "Extracted text content", @document.ocr_content
  end

  test "job marks document as skipped when no content extracted" do
    original_method = Aven::Agentic::Ocr::Processor.method(:process)
    Aven::Agentic::Ocr::Processor.define_singleton_method(:process) { |_doc| nil }

    begin
      Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
    ensure
      Aven::Agentic::Ocr::Processor.define_singleton_method(:process, original_method)
    end

    @document.reload
    assert_equal "skipped", @document.ocr_status
  end

  test "job marks document as failed on error" do
    original_method = Aven::Agentic::Ocr::Processor.method(:process)
    Aven::Agentic::Ocr::Processor.define_singleton_method(:process) { |_doc| raise StandardError, "OCR failed" }

    begin
      assert_nothing_raised do
        Aven::Agentic::DocumentOcrJob.perform_now(@document.id)
      end
    ensure
      Aven::Agentic::Ocr::Processor.define_singleton_method(:process, original_method)
    end

    @document.reload
    assert_equal "failed", @document.ocr_status
    assert_equal "OCR failed", @document.metadata["ocr_error"]
  end

  test "job skips documents not in pending status" do
    completed_doc = aven_agentic_documents(:pdf_document)
    completed_doc.file.attach(
      io: StringIO.new("fake content"),
      filename: completed_doc.filename,
      content_type: completed_doc.content_type
    )

    original_status = completed_doc.ocr_status

    # This shouldn't be called since doc is not pending
    Aven::Agentic::DocumentOcrJob.perform_now(completed_doc.id)

    completed_doc.reload
    assert_equal original_status, completed_doc.ocr_status
  end
end
