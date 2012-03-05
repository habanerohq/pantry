require 'pantry/exception'
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

    def use(options = {})
      puts "++ #{klass.name} #{id_values.inspect}"
      klass.send(:include, Pantry::Record) unless klass.descendants.include?(Pantry::Record) 
      klass.pantry ||= pantry
      @existing = apply_search(id_values, klass)
      begin
        @existing.any? ? send(options[:force] || pantry_options[:on_collision]) : save_model
      rescue Pantry::Exception => e
        puts e.message
      end
    end

    def to_model
      begin
        result = klass.new(attributes)
      rescue ActiveRecord::UnknownAttributeError, ActiveModel::MissingAttributeError => e
        pantry.log_exceptional(self)
        raise Pantry::Exception,
          "-- #{e.message} when using #{klass.name} #{id_values.inspect} ... deferring load for a subsequent pass."
      end
      foreign_values.symbolize_keys.each do |k, v|
        if v
          r = klass.reflect_on_association(k)
          f_class = foreign_class(r)
          f_objects = apply_search(v, f_class)
          if f_objects.any?
            result.send "#{r.foreign_key}=", f_objects.last.id
          else
            result.send "#{r.foreign_key}=", nil
            pantry.log_exceptional(self)
# => TODO: we may still need this stragey in future ... need to configure for it for each stackable
#            raise Pantry::Exception,
#              "-- No database record found for #{f_class} #{k}[#{v.inspect}] when using #{result.class.name} #{v.inspect} ... deferring load for a subsequent pass."
          end
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

      klass.find_by_sql(q.to_sql)
    end

    def gimme(search, klass, at, q)
      search.each do |k, v|
        if klass.attribute_names.include?(k.to_s)
          q = q.where(at[k.to_sym].eq(v))
        elsif a = klass.reflect_on_association(k)
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
