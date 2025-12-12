# frozen_string_literal: true

module Aven
  class Item::Schema::Builder
    attr_reader :fields, :embeds, :links

    def initialize
      @fields = {}
      @embeds = {}
      @links = {}
    end

    # Scalar fields
    def string(name, **opts)
      @fields[name] = { type: :string, **opts }
    end

    def integer(name, **opts)
      @fields[name] = { type: :integer, **opts }
    end

    def boolean(name, **opts)
      @fields[name] = { type: :boolean, **opts }
    end

    def date(name, **opts)
      @fields[name] = { type: :string, format: "date", **opts }
    end

    def datetime(name, **opts)
      @fields[name] = { type: :string, format: "date-time", **opts }
    end

    def array(name, of:, **opts)
      @fields[name] = { type: :array, items: { type: of }, **opts }
    end

    # Embeds with inline schema block
    def embeds_many(name, &block)
      embed_builder = EmbedBuilder.new
      embed_builder.instance_eval(&block) if block
      @embeds[name] = { cardinality: :many, fields: embed_builder.fields }
    end

    def embeds_one(name, &block)
      embed_builder = EmbedBuilder.new
      embed_builder.instance_eval(&block) if block
      @embeds[name] = { cardinality: :one, fields: embed_builder.fields }
    end

    # Links to other Items
    def links_many(name, class_name: "Aven::Item", inverse_of: nil)
      @links[name] = { cardinality: :many, class_name:, inverse_of: }
    end

    def links_one(name, class_name: "Aven::Item", inverse_of: nil)
      @links[name] = { cardinality: :one, class_name:, inverse_of: }
    end

    # JSON Schema generation
    def to_json_schema
      props = {}
      required = []

      fields.each do |name, config|
        props[name.to_s] = field_to_json_prop(config)
        required << name.to_s if config[:required]
      end

      embeds.each do |name, config|
        embed_schema = embed_to_json_schema(config[:fields])
        if config[:cardinality] == :many
          props[name.to_s] = { "type" => "array", "items" => embed_schema }
        else
          props[name.to_s] = embed_schema
        end
      end

      { "type" => "object", "properties" => props, "required" => required }
    end

    private

      def field_to_json_prop(config)
        prop = { "type" => config[:type].to_s }
        prop["format"] = config[:format] if config[:format]
        prop["enum"] = config[:enum] if config[:enum]
        prop["maxLength"] = config[:max_length] if config[:max_length]
        prop["minLength"] = config[:min_length] if config[:min_length]
        prop["items"] = { "type" => config[:items][:type].to_s } if config[:items]
        prop
      end

      def embed_to_json_schema(fields)
        props = {}
        required = []

        fields.each do |name, config|
          props[name.to_s] = field_to_json_prop(config)
          required << name.to_s if config[:required]
        end

        { "type" => "object", "properties" => props, "required" => required }
      end

      # Nested builder for embeds
      class EmbedBuilder
        attr_reader :fields

        def initialize
          @fields = {}
        end

        def string(name, **opts)
          @fields[name] = { type: :string, **opts }
        end

        def integer(name, **opts)
          @fields[name] = { type: :integer, **opts }
        end

        def boolean(name, **opts)
          @fields[name] = { type: :boolean, **opts }
        end

        def date(name, **opts)
          @fields[name] = { type: :string, format: "date", **opts }
        end

        def datetime(name, **opts)
          @fields[name] = { type: :string, format: "date-time", **opts }
        end

        def array(name, of:, **opts)
          @fields[name] = { type: :array, items: { type: of }, **opts }
        end
      end
  end
end
