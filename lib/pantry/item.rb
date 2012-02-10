module Pantry
  class Item
    attr_accessor :class_name, :id_values, :attributes, :foreign_values, :pantry
    
    def initialize(class_name, id_values, attributes, foreign_values, pantry = nil)
      @class_name = class_name
      @id_values = id_values.symbolize_keys
      @attributes = attributes.dup.compact.symbolize_keys
      @foreign_values = foreign_values.symbolize_keys
      @pantry = pantry 
    end
    
    def use
      klass.pantry ||= pantry
      @existing = klass.where(id_values).joins(klass.id_joins)
      @existing.any? ? send(pantry_options[:on_collision]) : save_model
    end

    def to_model
      result = klass.new(attributes)
      foreign_values.each do |k, v|
        if v
          r = klass.reflect_on_association(k)
          f = foreign_class(r)
          result.send "#{r.foreign_key}=", f.where(v).joins(f.foreign_joins).last.id
        end
      end
      result
    end
    
    def klass
      class_name.constantize
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