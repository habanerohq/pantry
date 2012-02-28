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
      @existing = apply_search(id_values, klass)
      @existing.any? ? send(pantry_options[:on_collision]) : save_model
    end

    def to_model
      result = klass.new(attributes)
      foreign_values.symbolize_keys.each do |k, v|
        if v
          r = klass.reflect_on_association(k)
          f = foreign_class(r)
          result.send "#{r.foreign_key}=", apply_search(v, f).last.id
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
  
    def apply_search(search, klass)
      at = klass.arel_table
      q = at.project(at['*'])
      
      q = gimme(search, klass, at, q)

      klass.where(klass.primary_key.to_sym => ActiveRecord::Base.connection.execute(q.to_sql).map{ |i| i[klass.primary_key].to_i })
    end
    
    def gimme(search, klass, at, q)
      search.each do |k, v|
        if klass.attribute_names.include?(k.to_s)
          q = q.where(at[k.to_sym].eq(v))
        elsif a = klass.association_for(k)
          jt = Arel::Table.new(a.table_name).alias("#{a.table_name}_#{v.object_id}")
          q = q.join(jt).on(at[a.foreign_key].eq(jt[klass.primary_key]))
          q = gimme(v, a.klass, jt, q)
        end
      end
      q
    end

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
