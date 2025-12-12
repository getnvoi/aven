# frozen_string_literal: true

module Aven
  class Item::Schemas::Note < Item::Schemas::Base
    string :title
    string :body, required: true
    datetime :noted_at
    array :tags, of: :string
  end
end
