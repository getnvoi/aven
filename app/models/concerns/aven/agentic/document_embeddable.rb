# frozen_string_literal: true

module Aven
  module Agentic
    module DocumentEmbeddable
      extend ActiveSupport::Concern

      included do
        # Override in subclasses to customize embedding behavior
      end

      # Split content into chunks for embedding
      def chunk_content(content, chunk_size: 1000, overlap: 200)
        return [] if content.blank?

        chunks = []
        position = 0

        while position < content.length
          chunk_end = [position + chunk_size, content.length].min
          chunks << content[position...chunk_end]
          position += (chunk_size - overlap)
        end

        chunks
      end

      # Generate embeddings for all chunks
      def generate_embeddings!
        return unless ocr_content.present?

        chunks = chunk_content(ocr_content)

        transaction do
          embeddings.destroy_all

          chunks.each_with_index do |chunk, index|
            embeddings.create!(
              chunk_index: index,
              content: chunk,
              embedding: nil # Will be filled by embedding service
            )
          end
        end
      end

      # Search similar chunks using vector similarity
      def self.search_similar(query_embedding, workspace:, limit: 10)
        Aven::Agentic::DocumentEmbedding
          .joins(:document)
          .where(aven_agentic_documents: { workspace_id: workspace.id })
          .where.not(embedding: nil)
          .order(Arel.sql("embedding <-> '#{query_embedding}'"))
          .limit(limit)
      end
    end
  end
end
