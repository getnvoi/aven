# frozen_string_literal: true

module Aven
  module Item::Schemaed
    extend ActiveSupport::Concern

    # Runtime schema access - delegates to resolved_schema (code class or DB record)
    def schema_fields
      schema_source = resolved_schema
      return {} unless schema_source

      # Code class has .fields, DB record has .fields_config
      schema_source.respond_to?(:fields) ? schema_source.fields : schema_source.fields_config
    end

    def schema_embeds
      schema_source = resolved_schema
      return {} unless schema_source

      schema_source.respond_to?(:embeds) ? schema_source.embeds : schema_source.embeds_config
    end

    def schema_links
      schema_source = resolved_schema
      return {} unless schema_source

      schema_source.respond_to?(:links) ? schema_source.links : schema_source.links_config
    end

    def json_schema
      resolved_schema&.to_json_schema
    end

    # Embed accessors
    def read_embed_many(name)
      cache_key = "@_embed_cache_#{name}"
      return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)

      raw = data[name.to_s] || []
      embeds = raw.map { |attrs| Item::Embed.new(attrs) }
      instance_variable_set(cache_key, embeds)
    end

    def write_embed_many(name, value)
      cache_key = "@_embed_cache_#{name}"
      remove_instance_variable(cache_key) if instance_variable_defined?(cache_key)

      data[name.to_s] = Array(value).map do |v|
        v.is_a?(Item::Embed) ? v.to_h : v
      end
    end

    def read_embed_one(name)
      cache_key = "@_embed_cache_#{name}"
      return instance_variable_get(cache_key) if instance_variable_defined?(cache_key)

      raw = data[name.to_s]
      embed = raw ? Item::Embed.new(raw) : nil
      instance_variable_set(cache_key, embed)
    end

    def write_embed_one(name, value)
      cache_key = "@_embed_cache_#{name}"
      remove_instance_variable(cache_key) if instance_variable_defined?(cache_key)

      data[name.to_s] = case value
      when Item::Embed then value.to_h
      when Hash then value
      when nil then nil
      end
    end

    def build_embed(name, attrs = {})
      Item::Embed.new(attrs.merge(id: SecureRandom.uuid))
    end

    # Link accessors
    def read_link_many(name)
      return Aven::Item.none unless persisted?

      Aven::Item.active
          .joins("INNER JOIN aven_item_links ON aven_item_links.target_id = aven_items.id")
          .where(aven_item_links: { source_id: id, relation: name.to_s })
          .order("aven_item_links.position")
    end

    def read_link_many_ids(name)
      return [] unless persisted?

      Aven::ItemLink.where(source_id: id, relation: name.to_s)
              .ordered
              .pluck(:target_id)
    end

    def write_link_many_ids(name, ids)
      @_pending_links ||= {}
      @_pending_links[name] = Array(ids).reject(&:blank?)
    end

    def read_link_one(name)
      return nil unless persisted?

      Aven::Item.active
          .joins("INNER JOIN aven_item_links ON aven_item_links.target_id = aven_items.id")
          .where(aven_item_links: { source_id: id, relation: name.to_s })
          .first
    end

    def read_link_one_id(name)
      return nil unless persisted?

      Aven::ItemLink.find_by(source_id: id, relation: name.to_s)&.target_id
    end

    def write_link_one_id(name, target_id)
      @_pending_links ||= {}
      @_pending_links[name] = target_id.presence
    end

    # Dynamic method handling based on schema_slug
    def method_missing(method, *args, &block)
      method_str = method.to_s

      # Setter
      if method_str.end_with?("=")
        attr_name = method_str.chomp("=").to_sym
        return handle_setter(attr_name, args.first) if schema_has_attribute?(attr_name)
      # Getter
      elsif schema_has_attribute?(method)
        return handle_getter(method)
      end

      super
    end

    def respond_to_missing?(method, include_private = false)
      method_str = method.to_s
      attr_name = method_str.end_with?("=") ? method_str.chomp("=").to_sym : method

      schema_has_attribute?(attr_name) || super
    end

    private

      def schema_has_attribute?(name)
        name_str = name.to_s
        name_sym = name.to_sym

        # Check for *_ids pattern for links
        if name_str.end_with?("_ids")
          base = name_str.chomp("_ids").pluralize.to_sym
          return schema_links.key?(base)
        end

        # Check for *_id pattern for links_one
        if name_str.end_with?("_id")
          base = name_str.chomp("_id").to_sym
          return schema_links.key?(base) && schema_links[base][:cardinality] == :one
        end

        # Check for build_* pattern
        if name_str.start_with?("build_")
          base = name_str.delete_prefix("build_")
          singular_base = base.to_sym
          plural_base = base.pluralize.to_sym
          return schema_embeds.key?(singular_base) || schema_embeds.key?(plural_base)
        end

        # Check for *_attributes= pattern
        if name_str.end_with?("_attributes")
          base = name_str.chomp("_attributes").to_sym
          return schema_embeds.key?(base) || schema_links.key?(base)
        end

        schema_fields.key?(name_sym) || schema_embeds.key?(name_sym) || schema_links.key?(name_sym)
      end

      def handle_getter(name)
        name_str = name.to_s
        name_sym = name.to_sym

        # Link IDs getter
        if name_str.end_with?("_ids")
          base = name_str.chomp("_ids").pluralize.to_sym
          return read_link_many_ids(base)
        end

        # Link ID getter
        if name_str.end_with?("_id")
          base = name_str.chomp("_id").to_sym
          return read_link_one_id(base)
        end

        # Build helper
        if name_str.start_with?("build_")
          return build_embed(name_str.delete_prefix("build_"))
        end

        # Embed getter
        if schema_embeds.key?(name_sym)
          config = schema_embeds[name_sym]
          return config[:cardinality] == :many ? read_embed_many(name_sym) : read_embed_one(name_sym)
        end

        # Link getter
        if schema_links.key?(name_sym)
          config = schema_links[name_sym]
          return config[:cardinality] == :many ? read_link_many(name_sym) : read_link_one(name_sym)
        end

        # Field getter
        data[name_str]
      end

      def handle_setter(name, value)
        name_str = name.to_s
        name_sym = name.to_sym

        # Link IDs setter
        if name_str.end_with?("_ids")
          base = name_str.chomp("_ids").pluralize.to_sym
          return write_link_many_ids(base, value)
        end

        # Link ID setter
        if name_str.end_with?("_id")
          base = name_str.chomp("_id").to_sym
          return write_link_one_id(base, value)
        end

        # Attributes setter (nested attributes)
        if name_str.end_with?("_attributes")
          base = name_str.chomp("_attributes").to_sym
          if schema_embeds.key?(base)
            return process_embed_attributes(base, value)
          elsif schema_links.key?(base)
            return process_link_attributes(base, value)
          end
          return
        end

        # Embed setter
        if schema_embeds.key?(name_sym)
          config = schema_embeds[name_sym]
          return config[:cardinality] == :many ? write_embed_many(name_sym, value) : write_embed_one(name_sym, value)
        end

        # Field setter
        data[name_str] = value
      end
  end
end
