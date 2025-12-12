# frozen_string_literal: true

module Aven
  class Item::Schemas::Company < Item::Schemas::Base
    string :name, required: true
    string :industry
    string :website
    string :description
    array :tags, of: :string

    embeds_many :addresses do
      string :street
      string :city
      string :postal_code
      string :country
      boolean :is_primary
    end

    links_many :employees
    links_many :notes
  end
end
