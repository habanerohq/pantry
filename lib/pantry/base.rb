require_relative 'record'
module Pantry
  class Base
    def can_stack(*args)
      if args.last.is_a?(Hash)
        make_stackable(args.first)
        (@stackables ||= []) << args.first
        (@stackables_options ||= {})[args.first] = args.last
      else
        args.each{|a| make_stackable(a)}
        @stackables = (@stackables ||= []) + args
      end
    end
    
    def stackables
      @stackables ||= []
    end
    
    def stackables_options
      @stackables_options ||= {}
    end
    
    def stack
    end
  
    def use
    end
    
    def to_active_record(pantry_record)
      # {:class_name => self.class.name, :id_value => id_value, :attributes => attributes.symbolize_keys, :foreign_values => foreign_values}
      klass = pantry_record[:class_name].constantize
      result = klass.new(pantry_record[:attributes])
      pantry_record[:foreign_values].each do |k, v|
        if v
          _association_reflection = klass.reflect_on_association(k)
          _foreign_class = _association_reflection.klass
          result.send "#{_association_reflection.foreign_key}=",  _foreign_class.where(_foreign_class.id_value_method_names.first => v).last.id
        end
      end
      result
    end
    
    protected
    
    def make_stackable(sym)
      klass = "#{sym}".classify.constantize
      klass.send :include, Pantry::Record
      klass.pantry = self
    end
  end
end