require 'habanero/reflection'
module Pantry
  module Record
    extend ActiveSupport::Concern
    include Habanero::Reflection

    def to_pantry
      Pantry::Item.new(self.class.name, id_values, select_attributes, foreign_values)
    end

    def id_values
      id_value_method_names.
      each_with_object({}) do |i, o| 
        if v = self.send(i)
          o[i] = (association_for(i) ? v.id_values : v)
        end
      end
    end
    
    def select_attributes
      attributes.delete_if { |k, v| self.class.protected_attributes.include?(k.to_sym)}
    end
    
    def foreign_values
      self.class.reflect_on_all_associations(:belongs_to).
      each_with_object({}) do |a, o|
        ao = send a.name
        o[a.name] = ao.id_values if ao
      end
    end

    def id_value_method_names
      self.class.id_value_method_names
    end

    def pantry
      self.class.pantry
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
          # fix!
          # We commonly encounter crashes here when pantry is nil.
          # That is because pantry doesn't get set for dynamic subclasses of the class we are trying to stack.
          # Currently, we hack the pantry initialize method to trick it inot loading subclasses of the class we want to stack.
          # There are examples in the Habanero pantries that do this.
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
      
      def protected_attributes
        [:lft, :rgt]
      end
    end
  end
end