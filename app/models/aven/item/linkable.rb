# frozen_string_literal: true

module Aven
  module Item::Linkable
    extend ActiveSupport::Concern

    included do
      has_many :outgoing_links, class_name: "Aven::ItemLink", foreign_key: :source_id, dependent: :destroy
      has_many :incoming_links, class_name: "Aven::ItemLink", foreign_key: :target_id, dependent: :destroy

      after_save :persist_pending_links
    end

    private

      def persist_pending_links
        persist_pending_link_ids if @_pending_links.present?
        persist_pending_link_attrs if @_pending_link_attrs.present?

        @_pending_links = nil
        @_pending_link_attrs = nil
      end

      def persist_pending_link_ids
        @_pending_links.each do |relation_name, ids|
          config = schema_links[relation_name]
          next unless config

          # Delete existing links for this relation
          Aven::ItemLink.where(source_id: id, relation: relation_name.to_s).delete_all

          if config[:cardinality] == :many
            Array(ids).each_with_index do |target_id, position|
              next unless Aven::Item.exists?(target_id)
              Aven::ItemLink.create!(source_id: id, target_id: target_id, relation: relation_name.to_s, position: position)
            end
          else
            if ids.present? && Aven::Item.exists?(ids)
              Aven::ItemLink.create!(source_id: id, target_id: ids, relation: relation_name.to_s)
            end
          end
        end
      end

      def persist_pending_link_attrs
        @_pending_link_attrs.each do |relation_name, pending_data|
          config = pending_data[:config]
          attrs_list = pending_data[:attrs]
          target_schema_slug = pending_data[:target_schema_slug]

          if config[:cardinality] == :many
            persist_many_link_attrs(relation_name, attrs_list, target_schema_slug)
          else
            persist_one_link_attrs(relation_name, attrs_list.first, target_schema_slug)
          end
        end
      end

      def persist_many_link_attrs(relation_name, attrs_list, target_schema_slug)
        attrs_list.each_with_index do |attrs, position|
          attr_hash = attrs.with_indifferent_access

          if destroy_link_flag?(attr_hash)
            # Delete the link (not the target item)
            if attr_hash[:id].present?
              Aven::ItemLink.where(source_id: id, target_id: attr_hash[:id], relation: relation_name.to_s).delete_all
            end
          elsif attr_hash[:id].present?
            # Update existing
            target = Aven::Item.find_by(id: attr_hash[:id])
            if target
              update_item_data(target, attr_hash.except(:id, :_destroy))
              # Update position if link exists
              link = Aven::ItemLink.find_by(source_id: id, target_id: target.id, relation: relation_name.to_s)
              link&.update!(position: position)
            end
          else
            # Create new
            next if attr_hash.except(:_destroy).blank?

            data_attrs, nested_attrs = split_attrs(attr_hash)
            target = Aven::Item.create!(
              workspace: workspace,
              schema_slug: target_schema_slug,
              data: data_attrs
            )
            # Apply nested attributes after creation
            apply_nested_attrs(target, nested_attrs)
            Aven::ItemLink.create!(source_id: id, target_id: target.id, relation: relation_name.to_s, position: position)
          end
        end
      end

      def persist_one_link_attrs(relation_name, attrs, target_schema_slug)
        return unless attrs

        attr_hash = attrs.with_indifferent_access

        if destroy_link_flag?(attr_hash)
          # Delete the link
          Aven::ItemLink.where(source_id: id, relation: relation_name.to_s).delete_all
        elsif attr_hash[:id].present?
          # Update existing
          target = Aven::Item.find_by(id: attr_hash[:id])
          update_item_data(target, attr_hash.except(:id, :_destroy)) if target
        else
          # Create new - first remove existing link
          Aven::ItemLink.where(source_id: id, relation: relation_name.to_s).delete_all
          return if attr_hash.except(:_destroy).blank?

          data_attrs, nested_attrs = split_attrs(attr_hash)
          target = Aven::Item.create!(
            workspace: workspace,
            schema_slug: target_schema_slug,
            data: data_attrs
          )
          # Apply nested attributes after creation
          apply_nested_attrs(target, nested_attrs)
          Aven::ItemLink.create!(source_id: id, target_id: target.id, relation: relation_name.to_s)
        end
      end

      def update_item_data(item, attrs)
        attrs.each do |key, value|
          key_str = key.to_s
          # Handle nested attributes (e.g., notes_attributes)
          if key_str.end_with?("_attributes")
            item.send("#{key_str}=", value)
          else
            item.data[key_str] = value
          end
        end
        item.save!
      end

      def split_attrs(attrs)
        # Split attrs into data fields and nested *_attributes
        data_attrs = {}
        nested_attrs = {}

        attrs.each do |key, value|
          key_str = key.to_s
          next if key_str == "id" || key_str == "_destroy"

          if key_str.end_with?("_attributes")
            nested_attrs[key_str] = value
          else
            data_attrs[key_str] = value
          end
        end

        [data_attrs, nested_attrs]
      end

      def apply_nested_attrs(item, nested_attrs)
        return if nested_attrs.blank?

        nested_attrs.each do |key, value|
          item.send("#{key}=", value)
        end
        item.save!
      end

      def clean_link_attrs(attrs)
        # Only return data fields (exclude id, _destroy, and *_attributes)
        result = {}
        attrs.each do |key, value|
          key_str = key.to_s
          next if key_str == "id" || key_str == "_destroy" || key_str.end_with?("_attributes")
          result[key_str] = value
        end
        result
      end

      def destroy_link_flag?(attrs)
        val = attrs[:_destroy] || attrs["_destroy"]
        val == "1" || val == true
      end

      def process_link_attributes(name, attrs)
        config = schema_links[name]
        return unless config

        # Derive target schema_slug from link name (e.g., :notes => "note", :company => "company")
        target_schema_slug = name.to_s.singularize

        @_pending_link_attrs ||= {}
        @_pending_link_attrs[name] = {
          config: config,
          attrs: normalize_link_attrs(attrs, config[:cardinality]),
          target_schema_slug: target_schema_slug
        }
      end

      def normalize_link_attrs(attrs, cardinality)
        case attrs
        when Array
          attrs
        when Hash
          if attrs.keys.all? { |k| k.to_s =~ /\A\d+\z/ }
            attrs.values
          elsif cardinality == :many
            [attrs]
          else
            [attrs]
          end
        else
          []
        end
      end
  end
end
