module PantryTest
  class Composite < ActiveRecord::Base
    belongs_to :whole, :class_name => 'Composite'
    has_many :parts, :class_name => 'Composite', :foreign_key => :whole_id
  end
end
