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
    
    protected
    
    def make_stackable(sym)
      klass = "#{sym}".classify.constantize
      klass.send :include, Pantry::Record
      klass.pantry = self
    end
  end
end