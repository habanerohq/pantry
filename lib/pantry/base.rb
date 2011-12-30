require_relative 'record'
module Pantry
  class Base
    def can_stack(*args)
      @stackables = args
      @stackables.each do |a|
        "#{a}".classify.constantize.send :include, Pantry::Record
      end
    end
    
    def stackables
      @stackables ||= []
    end
    
    def stack
    end
  
    def use
    end
  end
end