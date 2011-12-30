module Pantry
  module Record
    def to_pantry
      {:attributes => attributes.symbolize_keys, :foreign_values => foreign_values}
    end
    
    def foreign_values
    end
    
    def id_value_method_names
      [[:descriptor, :name, :label, :title].detect{|sym| respond_to?(sym)}]
    end
    
    def id_values
      id_value_method_names.inject({}){|m, i| m[i] = self.send i; m}
    end
    
    def id_value
      id_values.values.join(' ')
    end
  end
end