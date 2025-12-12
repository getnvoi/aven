# frozen_string_literal: true

module Aven
  class Item::Embed
    include ActiveModel::Model
    include ActiveModel::Attributes

    attr_accessor :id, :_destroy

    def initialize(attrs = {})
      @attributes = (attrs || {}).with_indifferent_access
      @id = @attributes["id"]
    end

    def [](key)
      @attributes[key]
    end

    def []=(key, value)
      @attributes[key] = value
    end

    def to_h
      @attributes.to_h
    end

    alias_method :to_hash, :to_h

    def persisted?
      id.present?
    end

    def new_record?
      !persisted?
    end

    def marked_for_destruction?
      _destroy == "1" || _destroy == true
    end

    def method_missing(method, *args)
      key = method.to_s
      if key.end_with?("=")
        @attributes[key.chomp("=")] = args.first
      else
        @attributes[key]
      end
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end
  end
end
