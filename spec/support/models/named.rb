module PantryTest
  class Named < ActiveRecord::Base
    has_many :assets, :as => :owner, :class_name => 'Composite', :dependent => :destroy
  end
end
