module Pantry
  class Railtie < Rails::Railtie
    rake_tasks do
      load File.expand_path('../../tasks/pantry.rake', __FILE__)
    end
  end
end
