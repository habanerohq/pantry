require 'rails/generators'
require 'rails/generators/active_record'

class Pantry::CellarGenerator < Rails::Generators::Base
  include Rails::Generators::Migration
  extend ActiveRecord::Generators::Migration

  source_root File.expand_path('../templates', __FILE__)

  def copy_files(*args)
    migration_template 'create_cellar_items.rb', 'db/migrate/create_cellar_items.rb'
  end
end
