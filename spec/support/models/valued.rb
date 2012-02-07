module PantryTest
  class Valued < ActiveRecord::Base
    validates :value, :uniqueness => {:scope => :discriminator}
  end
end
