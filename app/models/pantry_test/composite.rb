module PantryTest
  class Composite < ActiveRecord::Base
    belongs_to :whole, :class_name => 'Composite'
    belongs_to :owner, :polymorphic => true
    has_many :parts, :class_name => 'Composite', :foreign_key => :whole_id
  end
end
