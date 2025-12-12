# frozen_string_literal: true

module Aven
  class Item::Schemas::Contact < Item::Schemas::Base
    string :first_name, required: true
    string :last_name
    string :email
    string :phone

    embeds_many :addresses do
      string :street
      string :city
      string :postal_code
      string :country
      boolean :is_primary
    end

    embeds_many :phones do
      string :number, required: true
      string :label
      boolean :is_primary
    end

    embeds_many :emails do
      string :address, required: true
      string :label
      boolean :is_primary
    end

    links_one :company
    links_many :notes
  end
end
