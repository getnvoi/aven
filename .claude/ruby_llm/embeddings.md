# Embeddings | RubyLLM

Transform text into numerical vectors for semantic search, recommendations, and content similarity

## [](#table-of-contents)Table of contents

1.  [Basic Embedding Generation](#basic-embedding-generation)
2.  [Embedding Multiple Texts](#embedding-multiple-texts)
3.  [Choosing Models](#choosing-models)
4.  [Choosing Dimensions](#choosing-dimensions)
5.  [Using Embedding Results](#using-embedding-results)
    1.  [Vector Properties](#vector-properties)
6.  [Using Embedding Results](#using-embedding-results-1)
7.  [Error Handling](#error-handling)
8.  [Performance and Best Practices](#performance-and-best-practices)
9.  [Rails Integration Example](#rails-integration-example)
10. [Next Steps](#next-steps)

---

After reading this guide, you will know:

- How to generate embeddings for single or multiple texts.
- How to choose specific embedding models.
- How to use the results, including calculating similarity.
- How to handle errors during embedding generation.
- Best practices for performance and large datasets.
- How to integrate embeddings in a Rails application.

## [](#basic-embedding-generation)Basic Embedding Generation

The simplest way to create an embedding is with the global `RubyLLM.embed` method:

```
# Create an embedding for a single text
embedding = RubyLLM.embed("Ruby is a programmer's best friend")

# The vector representation (an array of floats)
vector = embedding.vectors
puts "Vector dimension: #{vector.length}" # e.g., 1536 for text-embedding-3-small

# Access metadata
puts "Model used: #{embedding.model}"
puts "Input tokens: #{embedding.input_tokens}"

```

## [](#embedding-multiple-texts)Embedding Multiple Texts

You can efficiently embed multiple texts in a single API call:

```
texts = ["Ruby", "Python", "JavaScript"]
embeddings = RubyLLM.embed(texts)

# Each text gets its own vector within the `vectors` array
puts "Number of vectors: #{embeddings.vectors.length}" # => 3
puts "First vector dimensions: #{embeddings.vectors.first.length}"
puts "Model used: #{embeddings.model}"
puts "Total input tokens: #{embeddings.input_tokens}"

```

> Batching multiple texts is generally more performant and cost-effective than making individual requests for each text.

## [](#choosing-models)Choosing Models

By default, RubyLLM uses a capable default embedding model (like OpenAI’s `text-embedding-3-small`), but you can specify a different one using the `model:` argument.

```
# Use a specific OpenAI model
embedding_large = RubyLLM.embed(
  "This is a test sentence",
  model: "text-embedding-3-large"
)

# Or use a Google model
embedding_google = RubyLLM.embed(
  "This is another test sentence",
  model: "text-embedding-004" # Google's model
)

# Use a model not in the registry (useful for custom endpoints)
embedding_custom = RubyLLM.embed(
  "Custom model test",
  model: "my-custom-embedding-model",
  provider: :openai,
  assume_model_exists: true
)

```

You can configure the default embedding model globally:

```
RubyLLM.configure do |config|
  config.default_embedding_model = "text-embedding-3-large"
end

```

Refer to the [Working with Models Guide](https://rubyllm.com/models/) for details on finding available embedding models and their capabilities.

## [](#choosing-dimensions)Choosing Dimensions

Each embedding model has its own default output dimensions. For example, OpenAI’s `text-embedding-3-small` outputs 1536 dimensions by default, while `text-embedding-3-large` outputs 3072 dimensions. RubyLLM allows you to specify these dimensions per request:

```
embedding = RubyLLM.embed(
  "This is a test sentence",
  model: "text-embedding-3-small",
  dimensions: 512
)

```

This is particularly useful when:

- Working with vector databases that have specific dimension requirements
- Ensuring consistent dimensionality across different requests
- Optimizing storage and query performance in your vector database

Note that not all models support custom dimensions. If you specify dimensions that aren’t supported by the chosen model, RubyLLM will use the model’s default dimensions.

## [](#using-embedding-results)Using Embedding Results

### [](#vector-properties)Vector Properties

The embedding result contains useful information:

```
embedding = RubyLLM.embed("Example text")

# The vector representation
puts embedding.vectors.class  # => Array
puts embedding.vectors.first.class  # => Float

# The vector dimensions
puts embedding.vectors.first.length # => 1536

# The model used
puts embedding.model  # => "text-embedding-3-small"

```

## [](#using-embedding-results-1)Using Embedding Results

A primary use case for embeddings is measuring the semantic similarity between texts. Cosine similarity is a common metric.

```
require 'matrix' # Ruby's built-in Vector class requires 'matrix'

embedding1 = RubyLLM.embed("I love Ruby programming")
embedding2 = RubyLLM.embed("Ruby is my favorite language")

# Convert embedding vectors to Ruby Vector objects
vector1 = Vector.elements(embedding1.vectors)
vector2 = Vector.elements(embedding2.vectors)

# Calculate cosine similarity (value between -1 and 1, closer to 1 means more similar)
similarity = vector1.inner_product(vector2) / (vector1.norm * vector2.norm)
puts "Similarity: #{similarity.round(4)}" # => e.g., 0.9123

```

## [](#error-handling)Error Handling

Embedding API calls can fail for various reasons. Handle errors gracefully:

```
begin
  embedding = RubyLLM.embed("Your text here")
  # Process embedding...
rescue RubyLLM::Error => e
  # Handle API errors
  puts "Embedding failed: #{e.message}"
end

```

For comprehensive error handling patterns and retry strategies, see the [Error Handling Guide](https://rubyllm.com/error-handling/).

## [](#performance-and-best-practices)Performance and Best Practices

- **Batching:** Always embed multiple texts in a single call when possible. `RubyLLM.embed(["text1", "text2"])` is much faster than calling `RubyLLM.embed` twice.
- **Caching/Persistence:** Embeddings are generally static for a given text and model. Store generated embeddings in your database or cache instead of regenerating them frequently.
- **Dimensionality:** Different models produce vectors of different lengths (dimensions). Ensure your storage and similarity calculation methods handle the correct dimensionality (e.g., `text-embedding-3-small` uses 1536 dimensions, `text-embedding-3-large` uses 3072).
- **Normalization:** Some vector databases and similarity algorithms perform better if vectors are normalized (scaled to have a length/magnitude of 1). Check the documentation for your specific use case or database.

## [](#rails-integration-example)Rails Integration Example

In a Rails application using PostgreSQL with the `pgvector` extension, you might store and search embeddings like this:

```
# Migration:
# add_column :documents, :embedding, :vector, limit: 1536 # Match your model's dimensions

# app/models/document.rb
class Document < ApplicationRecord
  has_neighbors :embedding # From the neighbor gem for pgvector

  # Automatically generate embedding before saving if content changed
  before_save :generate_embedding, if: :content_changed?

  # Scope for nearest neighbor search
  scope :search_by_similarity, ->(query_text, limit: 5) {
    query_embedding = RubyLLM.embed(query_text).vectors
    nearest_neighbors(:embedding, query_embedding, distance: :cosine).limit(limit)
  }

  private

  def generate_embedding
    return if content.blank?
    puts "Generating embedding for Document #{id}..."
    begin
      embedding_result = RubyLLM.embed(content) # Uses default embedding model
      self.embedding = embedding_result.vectors
    rescue RubyLLM::Error => e
      errors.add(:base, "Failed to generate embedding: #{e.message}")
      # Prevent saving if embedding fails (optional, depending on requirements)
      throw :abort
    end
  end
end

# Usage in controller or console:
# Document.create(title: "Intro to Ruby", content: "Ruby is a dynamic language...")
# results = Document.search_by_similarity("What is Ruby?")
# results.each { |doc| puts "- #{doc.title}" }

```

> This Rails example assumes you have the `pgvector` extension enabled in PostgreSQL and are using a gem like `neighbor` for ActiveRecord integration.

## [](#next-steps)Next Steps

Now that you understand embeddings, you might want to explore:

- [Chatting with AI Models](https://rubyllm.com/chat/) for interactive conversations.
- [Using Tools](https://rubyllm.com/tools/) to extend AI capabilities.
- [Error Handling](https://rubyllm.com/error-handling/) for building robust applications.

---
