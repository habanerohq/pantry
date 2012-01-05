require_relative 'record'
require_relative 'base'
module Pantry
  class Item
    attr_accessor :class_name, :id_values, :attributes, :foreign_values
    
    def initialize(class_name, id_values, attributes, foreign_values)
      @class_name = class_name
      @id_values = id_values.symbolize_keys
      @attributes = attributes.symbolize_keys
      @foreign_values = foreign_values.symbolize_keys
    end
    
    def use
      @existing = klass.where(id_values)
      @existing.any? ? send(pantry_options[:on_collision]) : save_model
    end

    def to_model
      result = klass.new(attributes)
      foreign_values.each do |k, v|
        if v
          r = klass.reflect_on_association(k)
          f = foreign_class(r)
          result.send "#{r.foreign_key}=", f.where(v).last.id
        end
      end
      result
    end
    
    def klass
      class_name.constantize
    end
    
    def pantry
      klass.pantry
    end
    
    def pantry_options
      pantry.options_for(klass)
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
    
    def replace
      o = @existing.last
      o.attributes = to_model.attributes
      o.save!
    end

    def save_model
      to_model.save!
    end
  end
end