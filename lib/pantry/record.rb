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
          m[a.name] = ao.id_values if ao
          m
        end
      end

      def id_value_method_names
        self.class.id_value_method_names
      end
    
      def id_values
        id_value_method_names.inject({}) do |m, i| 
          if v = self.send(i)
            a = association_for(i)
            a ? (m[a.klass.table_name] = v.id_values) : (m[i] = v)
          end
          m
        end
      end
    
      def id_value
        id_values.values.join(' ')
      end
      
      def association_for(s)
        self.class.association_for(s)
      end
    end

    module ClassMethods
      attr_accessor :pantry

      def foreign_joins(classes = [])
        reflect_on_all_associations(:belongs_to).map do |a|
          cs = classes << self
          { a.name => a.klass.foreign_joins(cs) } unless cs.include?(a.klass)
        end.compact
      end
      
      def id_joins
        id_value_method_names.map do |i|
          a = association_for(i)
          { a.name => a.klass.id_joins } if a
        end.flatten.compact
      end
      
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
      
      def association_for(s)
        reflect_on_association(s.to_sym)
      end
    end
  end
end