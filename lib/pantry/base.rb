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

    def refers_to(*args)
      if args.last.is_a?(Hash)
        make_stackable(args.first)
        (@stackables_options ||= {})[args.first] = args.last
      else
        args.each{|a| make_stackable(a)}
      end
    end
    
    def stackables
      @stackables ||= []
    end
    
    def stackables_options
      @stackables_options ||= {}
    end
    
    def options_for(stackable)
      {:on_collision => :skip}.merge(stackables_options.detect{ |s| stackable.ancestors.include?(s.first) }.try(:last) || {})
    end
    
    def stack
      fn = next_generation
      FileUtils.mkpath(path)
      File.open(fn, 'wb') do |f|
        stackables.each do |s|
          candidates(s).each do |r|
            f.write "#{r.to_pantry.to_json}#{record_separator}"
          end
        end
      end
    end
  
    def use
      fn = generation_name
      begin
        File.open(fn, 'r').each(record_separator) do |l|
          j = JSON.parse(l).symbolize_keys
          Pantry::Item.new(j[:class_name], j[:id_values], j[:attributes], j[:foreign_values], self).use
        end
      rescue Errno::ENOENT => e
        puts "ERROR: Pantry#use ---> #{e}"
      end
    end
    
    def path
      Rails.root.join('data/pantries')
    end
    
    protected
    
    def make_stackable(sym)
      klass = "#{sym}".classify.constantize
      klass.send :include, Pantry::Record
      (klass.descendants << klass).each do |k|
        k.pantry = self
      end
    end

    def candidates(klass)
      s = options_for(klass)[:scope]
      s ? s.inject(klass){|m, i| m.send(*i)} : klass.all
    end
    
    def file_name(gen)
      "#{path}/#{self.class.name.underscore}_#{gen}.pantry"
    end
    
    def next_generation
      file_name((generation_numbers.last || 0) + 1)
    end
    
    def generation_name(i=0)
      i > 0 ? i : file_name(generation_numbers[i - 1])
    end
    
    def generation_numbers
      Dir.glob("#{path}/#{self.class.name.underscore}*.pantry").map do |fn|
        fn.split('.').first.split('_').last.to_i
      end.sort
    end
    
    def record_separator
      "\n"
    end
  end
end