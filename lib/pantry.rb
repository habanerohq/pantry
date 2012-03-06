require 'pantry/core_ext'

module Pantry
  autoload :Base,       'pantry/base'
  autoload :Item,       'pantry/item'
  autoload :Record,     'pantry/record'
  autoload :Observer,   'pantry/observer'
  autoload :CellarItem, 'pantry/cellar_item'

end

require 'pantry/railtie' if defined?(Rails)

