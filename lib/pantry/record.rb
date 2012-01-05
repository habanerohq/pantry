require_relative 'item'
module Pantry
  module Record
    extend ActiveSupport::Concern

    module InstanceMethods
      def to_pantry
        Pantry::Item.new(self.class.name, id_values, attributes, foreign_values)
      end
    
      def foreign_values
        self.class.reflect_on_all_associations(:belongs_to).
          inject({}) do |m, a|
            ao = self.send a.name
            m[a.name] = (ao ? ao.id_values : nil)
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
        [
          pantry.options_for(self)[:id_value_methods] ||
            id_value_method_precedence.detect(lambda {id_value_method_names_from_uniqueness_validator}){|sym| attribute_names.include?(sym.to_s)}
        ].flatten
      end
      
      def id_value_method_precedence
        [:descriptor, :name, :label, :title]
      end
      
      def id_value_method_names_from_uniqueness_validator
        uv = validators.detect{|v| v.class == ActiveRecord::Validations::UniquenessValidator}
        [uv.options[:scope], uv.attributes].flatten.compact if uv
      end
    end
  end
end