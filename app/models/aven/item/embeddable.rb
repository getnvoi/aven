# frozen_string_literal: true

module Aven
  module Item::Embeddable
    extend ActiveSupport::Concern

    included do
      before_validation :assign_embed_ids
    end

    private

      def assign_embed_ids
        return if data.nil?
        return if schema_slug.blank?

        # Guard against schema not found - let validation handle the error
        embeds = begin
          schema_embeds
        rescue ActiveRecord::RecordNotFound
          {}
        end

        return if embeds.blank?

        embeds.each do |name, config|
          if config[:cardinality] == :many
            assign_many_embed_ids(name)
          else
            assign_one_embed_id(name)
          end
        end
      end

      def assign_many_embed_ids(name)
        embeds = data[name.to_s]
        return if embeds.blank?

        embeds.each do |embed|
          embed["id"] ||= SecureRandom.uuid
        end
      end

      def assign_one_embed_id(name)
        embed = data[name.to_s]
        return if embed.blank?

        embed["id"] ||= SecureRandom.uuid
      end

      def process_embed_attributes(name, attrs)
        config = schema_embeds[name]
        return unless config

        # Clear cache
        cache_key = "@_embed_cache_#{name}"
        remove_instance_variable(cache_key) if instance_variable_defined?(cache_key)

        if config[:cardinality] == :many
          process_many_embed_attributes(name, attrs)
        else
          process_one_embed_attributes(name, attrs)
        end
      end

      def process_many_embed_attributes(name, attrs)
        normalized = normalize_attrs(attrs)
        existing = (data[name.to_s] || []).dup

        normalized.each do |attr_hash|
          if destroy_flag?(attr_hash)
            # Remove by id if present
            existing.reject! { |e| e["id"] == attr_hash["id"] } if attr_hash["id"]
          elsif attr_hash["id"].present?
            # Update existing
            idx = existing.index { |e| e["id"] == attr_hash["id"] }
            if idx
              existing[idx] = existing[idx].merge(clean_attrs(attr_hash))
            else
              existing << clean_attrs(attr_hash.merge("id" => SecureRandom.uuid))
            end
          else
            # New embed
            existing << clean_attrs(attr_hash.merge("id" => SecureRandom.uuid))
          end
        end

        data[name.to_s] = existing
      end

      def process_one_embed_attributes(name, attrs)
        attr_hash = single_attrs(attrs)

        if destroy_flag?(attr_hash)
          data[name.to_s] = nil
        elsif data[name.to_s].present?
          data[name.to_s] = data[name.to_s].merge(clean_attrs(attr_hash))
        else
          data[name.to_s] = clean_attrs(attr_hash.merge("id" => SecureRandom.uuid))
        end
      end

      def normalize_attrs(attrs)
        case attrs
        when Array
          attrs.map(&:with_indifferent_access)
        when Hash
          # Could be indexed hash like {"0" => {...}, "1" => {...}}
          if attrs.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
            attrs.values.map(&:with_indifferent_access)
          else
            [attrs.with_indifferent_access]
          end
        else
          []
        end
      end

      def single_attrs(attrs)
        case attrs
        when Hash
          if attrs.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
            attrs.values.first&.with_indifferent_access || {}.with_indifferent_access
          else
            attrs.with_indifferent_access
          end
        else
          {}.with_indifferent_access
        end
      end

      def clean_attrs(hash)
        hash.except(:_destroy, "_destroy").transform_keys(&:to_s)
      end

      def destroy_flag?(attrs)
        val = attrs[:_destroy] || attrs["_destroy"]
        val == "1" || val == true
      end
  end
end
