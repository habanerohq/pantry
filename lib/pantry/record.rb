module Pantry
  module Record
    extend ActiveSupport::Concern

    module InstanceMethods
      def to_pantry
        {:attributes => attributes.symbolize_keys, :foreign_values => foreign_values}
      end
    
      def foreign_values
        self.class.reflect_on_all_associations(:belongs_to).
          inject({}) {|m, a| m[a.name] = (self.send a.name).id_value; m}
      end

      def id_value_method_names
        [self.class.id_value_method_prcedence.detect{|sym| respond_to?(sym)}]
      end
    
      def id_values
        id_value_method_names.inject({}){|m, i| m[i] = self.send i; m}
      end
    
      def id_value
        id_values.values.join(' ')
      end
    end

    module ClassMethods
      attr_accessor :pantry
      
      def id_value_method_prcedence
        if o = pantry.stackables_options[self]
          [o[:id_value_method]]
        else
          [:descriptor, :name, :label, :title]
        end
      end
    end
  end
end