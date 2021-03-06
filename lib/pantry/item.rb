require 'pantry/exception'
module Pantry
  class Item
    attr_accessor :class_name, :action, :id_values, :attributes, :foreign_values, :pantry, :old_attributes

    def initialize(class_name, action, id_values, attributes, foreign_values, pantry = nil)
      @class_name = class_name
      @action = action
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
#        ActiveRecord::Base.observers.disable :all do
          if @existing.any?
            if action == 'destroy'
              destroy_model
            else
              send(options[:force] || pantry_options[:on_collision])
            end
          else
            save_model
          end
#        end
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
      q = at.project(at[Arel.star])
      q = gimme(search, klass, at, q)

      klass.find_by_sql(q.to_sql)
    end

    def gimme(search, klass, at, q)
      search.each do |k, v|
        if klass.attribute_names.include?(k.to_s)
          q = q.where(at[k.to_sym].eq(v))
        elsif a = klass.reflect_on_association(k.to_sym)
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
      # todo: @existing should never have more than one element. what do we do if it has?
      o = @existing.last

      if old_attributes.present?
        conflicts = o.attributes.reject { |k, v| !old_attributes.keys.include?(k) }.diff(old_attributes)
        conflicts.each do |k, v|
          puts "EXPECTING #{k} TO BE #{old_attributes[k]} BUT GOT #{v} ON #{o.inspect}"
        end
      end

      o.attributes = to_model.attributes.reject { |k, v| to_model.class.protected_attributes.include?(k.to_sym) }
      save_it(o)
    end

    def save_model
      save_it(to_model)
    end

    def save_it(a_record)
      unless a_record.save
        raise Pantry::Exception,
          "-- #{a_record.errors.messages.inspect} when using #{klass.name} #{id_values.inspect}. Cannot use the record."
      end
    end

    def destroy_model
      # todo: @existing should never have more than one element. what do we do if it has?
      @existing.last.destroy
    end
  end
end
