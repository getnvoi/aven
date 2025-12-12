# frozen_string_literal: true

# == Schema Information
#
# Table name: aven_agentic_document_embeddings
#
#  id          :bigint           not null, primary key
#  chunk_index :integer          not null
#  content     :text             not null
#  embedding   :vector(1536)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  document_id :bigint           not null
#
# Indexes
#
#  idx_on_document_id_chunk_index_5fe199c056              (document_id,chunk_index) UNIQUE
#  index_aven_agentic_document_embeddings_on_document_id  (document_id)
#
# Foreign Keys
#
#  fk_rails_...  (document_id => aven_agentic_documents.id)
#
module Aven
  module Agentic
    class DocumentEmbedding < Aven::ApplicationRecord
      self.table_name = "aven_agentic_document_embeddings"

      belongs_to :document, class_name: "Aven::Agentic::Document"

      validates :chunk_index, presence: true, uniqueness: { scope: :document_id }
      validates :content, presence: true

      scope :ordered, -> { order(:chunk_index) }

      delegate :workspace, :workspace_id, to: :document
    end
  end
end
