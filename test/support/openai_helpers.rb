# frozen_string_literal: true

# WebMock stubs for OpenAI API calls
module OpenAIHelpers
  EMBEDDING_DIMENSION = 1536

  def stub_openai_embeddings(vectors: nil)
    vectors ||= Array.new(EMBEDDING_DIMENSION, 0.5)

    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          object: "list",
          data: [
            {
              object: "embedding",
              index: 0,
              embedding: vectors
            }
          ],
          model: "text-embedding-3-small",
          usage: {
            prompt_tokens: 10,
            total_tokens: 10
          }
        }.to_json
      )
  end

  def stub_openai_embeddings_error(status: 500, message: "API error")
    stub_request(:post, "https://api.openai.com/v1/embeddings")
      .to_return(
        status:,
        headers: { "Content-Type" => "application/json" },
        body: {
          error: {
            message:,
            type: "server_error",
            code: nil
          }
        }.to_json
      )
  end
end
