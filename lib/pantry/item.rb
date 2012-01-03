require_relative 'record'
require_relative 'base'
module Pantry
  class Item
    attr_accessor :class_name, :id_value, :attributes, :foreign_values
    
    def initialize(class_name, id_value, attributes, foreign_values)
      @class_name = class_name
      @id_value = id_value
      @attributes = attributes.symbolize_keys
      @foreign_values = foreign_values
    end

    def to_model
      result = klass.new(attributes)
      foreign_values.each do |k, v|
        if v
          _association_reflection = klass.reflect_on_association(k)
          _foreign_class = _association_reflection.klass
          result.send "#{_association_reflection.foreign_key}=",  _foreign_class.where(_foreign_class.id_value_method_names.first => v).last.id
        end
      end
      result
    end
    
    def klass
      class_name.constantize
    end
  end
end