require 'rubygems'
require 'bundler/setup'

require 'rspec'

require 'active_record'
require 'pantry'

# this is a kludge... although we only use ActiveRecord, Pantry::Base uses
# Rails to work out a base directory, and so do our tests
module Rails
  extend self

  def root
    @root ||= Pathname.new(File.dirname(File.dirname(__FILE__)))
  end
end

# requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

config = YAML::load_file(Rails.root.join('spec/config/database.yml'))
ActiveRecord::Base.establish_connection(config['test'])

ActiveRecord::Migration.verbose = false
ActiveRecord::Migrator.migrate(Rails.root.join('spec/db/migrate'))
