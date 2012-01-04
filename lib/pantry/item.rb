require_relative 'record'
require_relative 'base'
module Pantry
  class Item
    attr_accessor :class_name, :id_value, :attributes, :foreign_values
    
    def initialize(class_name, id_value, attributes, foreign_values)
      @class_name = class_name
      @id_value = id_value
      @attributes = attributes.symbolize_keys
      @foreign_values = foreign_values.symbolize_keys
    end
    
    def use
      existing = klass.where(klass.id_value_method_names.first => id_value)
      existing.any? ? skip : save_model
    end

    def to_model
      result = klass.new(attributes)
      foreign_values.each do |k, v|
        if v
          r = klass.reflect_on_association(k)
          f = foreign_class(r)
          result.send "#{r.foreign_key}=", f.where(f.id_value_method_names.first => v).last.id
        end
      end
      result
    end
    
    def klass
      class_name.constantize
    end
    
    def foreign_class(reflection)
      if reflection.options[:polymorphic]
        attributes[:"#{reflection.name}_type"].constantize
      else
        reflection.klass
      end
    end
    
    protected
    
    def skip
      #do nothing
    end

    def save_model
      to_model.save!
    end
  end
end