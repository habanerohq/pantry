require_relative 'item'
module Pantry
  module Record
    extend ActiveSupport::Concern

    module InstanceMethods
      def to_pantry
        Pantry::Item.new(self.class.name, id_value, attributes, foreign_values)
      end
    
      def foreign_values
        self.class.reflect_on_all_associations(:belongs_to).
          inject({}) do |m, a|
            ao = self.send a.name
            m[a.name] = (ao ? ao.id_value : nil)
            m
          end
      end

      def id_value_method_names
        self.class.id_value_method_names
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

      def id_value_method_names
        [id_value_method_precedence.detect{|sym| attribute_names.include?(sym.to_s)}]
      end
      
      def id_value_method_precedence
        if o = pantry.stackables_options[self]
          [o[:id_value_method]]
        else
          [:descriptor, :name, :label, :title]
        end
      end
    end
  end
end