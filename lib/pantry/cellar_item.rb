module Pantry
  class CellarItem < ActiveRecord::Base
    belongs_to :record
    scope :unstacked, where(:stacked_at => nil).order(:created_at)

    def to_pantry_item
      j = JSON.parse(item).symbolize_keys
      Pantry::Item.new(j[:class_name], j[:id_values], j[:attributes], j[:foreign_values], pantry_type.constantize.new)
    end
  end
end
