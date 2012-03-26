module Pantry
  class CellarItem < ActiveRecord::Base
    belongs_to :record, :polymorphic => true
    scope :unstacked, where(:stacked_at => nil).order(:created_at)

    def to_pantry_item
      j = JSON.parse(item).symbolize_keys
      item = Pantry::Item.new(j[:class_name], j[:action], j[:id_values], j[:attributes], j[:foreign_values], pantry_type.constantize.new)
      item.old_attributes = j[:old_attributes]
      item
    end
  end
end
