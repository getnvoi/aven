# == Schema Information
#
# Table name: aven_agentic_documents
#
#  id               :bigint           not null, primary key
#  byte_size        :bigint           not null
#  content_type     :string           not null
#  embedding_status :string           default("pending"), not null
#  filename         :string           not null
#  metadata         :jsonb
#  ocr_content      :text
#  ocr_status       :string           default("pending"), not null
#  processed_at     :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  workspace_id     :bigint           not null
#
# Indexes
#
#  index_aven_agentic_documents_on_content_type      (content_type)
#  index_aven_agentic_documents_on_embedding_status  (embedding_status)
#  index_aven_agentic_documents_on_ocr_status        (ocr_status)
#  index_aven_agentic_documents_on_workspace_id      (workspace_id)
#
# Foreign Keys
#
#  fk_rails_...  (workspace_id => aven_workspaces.id)
#
require "test_helper"

class Aven::Agentic::DocumentTest < ActiveSupport::TestCase
  # Helper to attach a fake file to a document
  def attach_file_to(document)
    document.file.attach(
      io: StringIO.new("fake content"),
      filename: document.filename,
      content_type: document.content_type
    )
  end
  # Associations
  test "belongs to workspace" do
    doc = aven_agentic_documents(:pdf_document)
    assert_respond_to doc, :workspace
    assert_equal aven_workspaces(:one), doc.workspace
  end

  test "has many embeddings" do
    doc = aven_agentic_documents(:pdf_document)
    assert_respond_to doc, :embeddings
    assert_kind_of ActiveRecord::Associations::CollectionProxy, doc.embeddings
  end

  test "has many agent_documents" do
    doc = aven_agentic_documents(:pdf_document)
    assert_respond_to doc, :agent_documents
    assert_kind_of ActiveRecord::Associations::CollectionProxy, doc.agent_documents
  end

  test "has many agents through agent_documents" do
    doc = aven_agentic_documents(:pdf_document)
    assert_respond_to doc, :agents
    assert_includes doc.agents, aven_agentic_agents(:research_agent)
  end

  test "has_one_attached file" do
    doc = aven_agentic_documents(:pdf_document)
    assert_respond_to doc, :file
  end

  # TenantModel
  test "includes TenantModel concern" do
    assert Aven::Agentic::Document.include?(Aven::Model::TenantModel)
  end

  test "in_workspace scope returns documents for workspace" do
    docs = Aven::Agentic::Document.in_workspace(aven_workspaces(:one))
    assert_includes docs, aven_agentic_documents(:pdf_document)
    assert_includes docs, aven_agentic_documents(:image_document)
  end

  # Constants
  test "ALLOWED_CONTENT_TYPES includes expected types" do
    assert_includes Aven::Agentic::Document::ALLOWED_CONTENT_TYPES, "application/pdf"
    assert_includes Aven::Agentic::Document::ALLOWED_CONTENT_TYPES, "image/png"
    assert_includes Aven::Agentic::Document::ALLOWED_CONTENT_TYPES, "image/jpeg"
  end

  test "MAX_FILE_SIZE is 30 megabytes" do
    assert_equal 30.megabytes, Aven::Agentic::Document::MAX_FILE_SIZE
  end

  # Scopes
  test "recent scope orders by created_at desc" do
    docs = Aven::Agentic::Document.recent
    assert_equal docs.to_a, docs.order(created_at: :desc).to_a
  end

  test "images scope returns image documents" do
    images = Aven::Agentic::Document.images
    assert_includes images, aven_agentic_documents(:image_document)
    assert_not_includes images, aven_agentic_documents(:pdf_document)
  end

  test "pdfs scope returns PDF documents" do
    pdfs = Aven::Agentic::Document.pdfs
    assert_includes pdfs, aven_agentic_documents(:pdf_document)
    assert_not_includes pdfs, aven_agentic_documents(:image_document)
  end

  test "with_ocr scope returns documents with completed OCR" do
    with_ocr = Aven::Agentic::Document.with_ocr
    assert_includes with_ocr, aven_agentic_documents(:pdf_document)
    assert_not_includes with_ocr, aven_agentic_documents(:image_document)
  end

  test "pending_ocr scope returns documents pending OCR" do
    pending = Aven::Agentic::Document.pending_ocr
    assert_includes pending, aven_agentic_documents(:image_document)
    assert_not_includes pending, aven_agentic_documents(:pdf_document)
  end

  # Type check methods
  test "image? returns true for image content types" do
    doc = aven_agentic_documents(:image_document)
    assert doc.image?
    assert_not doc.pdf?
  end

  test "pdf? returns true for PDF content type" do
    doc = aven_agentic_documents(:pdf_document)
    assert doc.pdf?
    assert_not doc.image?
  end

  test "word_doc? returns true for Word document" do
    doc = aven_agentic_documents(:word_document)
    assert doc.word_doc?
    assert_not doc.pdf?
  end

  test "ocr_required? returns true for images and PDFs" do
    assert aven_agentic_documents(:pdf_document).ocr_required?
    assert aven_agentic_documents(:image_document).ocr_required?
    assert_not aven_agentic_documents(:word_document).ocr_required?
  end

  # Status methods
  test "mark_ocr_processing! updates status" do
    doc = aven_agentic_documents(:image_document)
    attach_file_to(doc)
    doc.mark_ocr_processing!
    assert_equal "processing", doc.ocr_status
  end

  test "mark_ocr_completed! updates status and content" do
    doc = aven_agentic_documents(:image_document)
    attach_file_to(doc)
    doc.mark_ocr_completed!("Extracted text content")
    doc.reload

    assert_equal "completed", doc.ocr_status
    assert_equal "Extracted text content", doc.ocr_content
    assert_not_nil doc.processed_at
  end

  test "mark_ocr_failed! updates status and stores error" do
    doc = aven_agentic_documents(:image_document)
    attach_file_to(doc)
    doc.mark_ocr_failed!("OCR service unavailable")
    doc.reload

    assert_equal "failed", doc.ocr_status
    assert_equal "OCR service unavailable", doc.metadata["ocr_error"]
  end

  test "mark_ocr_skipped! updates status" do
    doc = aven_agentic_documents(:image_document)
    attach_file_to(doc)
    doc.mark_ocr_skipped!
    assert_equal "skipped", doc.ocr_status
  end

  test "mark_embedding_processing! updates status" do
    doc = aven_agentic_documents(:pdf_document)
    attach_file_to(doc)
    doc.mark_embedding_processing!
    assert_equal "processing", doc.embedding_status
  end

  test "mark_embedding_completed! updates status" do
    doc = aven_agentic_documents(:pdf_document)
    attach_file_to(doc)
    doc.update!(embedding_status: "processing")
    doc.mark_embedding_completed!
    assert_equal "completed", doc.embedding_status
  end

  test "mark_embedding_failed! updates status and stores error" do
    doc = aven_agentic_documents(:pdf_document)
    attach_file_to(doc)
    doc.mark_embedding_failed!("Embedding service error")
    doc.reload

    assert_equal "failed", doc.embedding_status
    assert_equal "Embedding service error", doc.metadata["embedding_error"]
  end

  # Destroy behavior
  test "destroying document destroys embeddings" do
    doc = aven_agentic_documents(:pdf_document)

    # Create an embedding for the document (1536 dimensions for OpenAI embeddings)
    embedding = Aven::Agentic::DocumentEmbedding.create!(
      document: doc,
      chunk_index: 0,
      content: "Test content",
      embedding: Array.new(1536) { rand(-1.0..1.0) }
    )

    doc.destroy!

    assert_not Aven::Agentic::DocumentEmbedding.exists?(embedding.id)
  end

  test "destroying document destroys agent_documents" do
    doc = aven_agentic_documents(:pdf_document)
    agent_doc = aven_agentic_agent_documents(:research_agent_pdf)

    doc.destroy!

    assert_not Aven::Agentic::AgentDocument.exists?(agent_doc.id)
  end
end
