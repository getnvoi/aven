# frozen_string_literal: true

module Aven
  class Item::Schemas::Base
    class_attribute :_builder

    class << self
      def inherited(subclass)
        super
        subclass._builder = Item::Schema::Builder.new
      end

      def slug
        name.demodulize.underscore
      end

      def builder
        _builder
      end

      # DSL methods delegate to builder
      def string(name, **opts)
        _builder.string(name, **opts)
      end

      def integer(name, **opts)
        _builder.integer(name, **opts)
      end

      def boolean(name, **opts)
        _builder.boolean(name, **opts)
      end

      def date(name, **opts)
        _builder.date(name, **opts)
      end

      def datetime(name, **opts)
        _builder.datetime(name, **opts)
      end

      def array(name, of:, **opts)
        _builder.array(name, of:, **opts)
      end

      def embeds_many(name, &block)
        _builder.embeds_many(name, &block)
      end

      def embeds_one(name, &block)
        _builder.embeds_one(name, &block)
      end

      def links_many(name, class_name: "Aven::Item", inverse_of: nil)
        _builder.links_many(name, class_name:, inverse_of:)
      end

      def links_one(name, class_name: "Aven::Item", inverse_of: nil)
        _builder.links_one(name, class_name:, inverse_of:)
      end

      def fields
        _builder&.fields || {}
      end

      def embeds
        _builder&.embeds || {}
      end

      def links
        _builder&.links || {}
      end

      def to_json_schema
        _builder&.to_json_schema
      end

      # Query helpers - delegate to Item scoped by schema_slug
      def all
        Aven::Item.by_schema(slug)
      end

      def where(...)
        all.where(...)
      end

      def find(...)
        all.find(...)
      end

      def find_by(...)
        all.find_by(...)
      end

      def create(attrs = {})
        Aven::Item.create(attrs.merge(schema_slug: slug))
      end

      def create!(attrs = {})
        Aven::Item.create!(attrs.merge(schema_slug: slug))
      end

      def new(attrs = {})
        Aven::Item.new(attrs.merge(schema_slug: slug))
      end
    end
  end
end
