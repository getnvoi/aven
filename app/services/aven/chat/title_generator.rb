# frozen_string_literal: true

module Aven
  module Chat
    class TitleGenerator
      MAX_TITLE_LENGTH = 100

      def initialize(thread, first_message)
        @thread = thread
        @first_message = first_message
      end

      # Generate a title for the thread based on first message
      def call
        return if @thread.title.present?

        title = generate_title
        @thread.update!(title: title) if title.present?
      end

      private

        def generate_title
          content = @first_message.content.to_s.strip
          return nil if content.blank?

          # Try LLM-based title generation if available
          llm_title = generate_with_llm(content)
          return llm_title if llm_title.present?

          # Fallback to simple truncation
          truncate_content(content)
        end

        def generate_with_llm(content)
          return nil unless defined?(RubyLLM)

          response = RubyLLM.chat(model: "claude-haiku-3-5-20241022")
            .with_instructions("Generate a short, descriptive title (max 50 chars) for a conversation that starts with this message. Return only the title, nothing else.")
            .ask(content)

          title = response.content.to_s.strip.gsub(/^["']|["']$/, "")
          title.presence
        rescue => e
          Rails.logger.warn("[Aven::Chat] LLM title generation failed: #{e.message}")
          nil
        end

        def truncate_content(content)
          # Take first sentence or first N characters
          first_sentence = content.split(/[.!?]/).first.to_s.strip

          if first_sentence.length <= MAX_TITLE_LENGTH
            first_sentence
          else
            content.truncate(MAX_TITLE_LENGTH, separator: " ")
          end
        end
    end
  end
end
