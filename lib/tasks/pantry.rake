require 'pp'

namespace :pantry do
  namespace :cellar do
    desc 'Dump items in the cellar to file'
    task :dump => :environment do
      fail "You're not using a Cellar" unless Pantry::CellarItem.table_exists?

      timestamp = Time.now

      pantries = Pantry::CellarItem.select(:pantry_type).uniq.map(&:pantry_type)
      pantries.each do |pantry|
        filepath = Rails.root.join("data/cellars/#{timestamp.to_i}_#{pantry.underscore}.pantry")
        items = Pantry::CellarItem.unstacked.where(:pantry_type => pantry)
        if items.any?
          FileUtils.mkpath(File.dirname(filepath))
          File.open(filepath, 'w') do |f|
            items.each do |item|
              # todo: set pantry value in json to nil?
              f.write item.to_pantry_item.to_json << "\n"
              item.update_attribute(:stacked_at, timestamp)
            end
          end
        end
      end
    end

    desc 'Load back stuff from the cellar'
    task :load => :environment do
      table = Arel::Table.new(:cellar_migrations)
      versions = ActiveRecord::Base.connection.select_values(table.project(table[:version])).map(&:to_i).sort

      files = Dir.glob(Rails.root.join('data/cellars/*.pantry')).sort
      files.each do |filepath|
        version, pantry = filepath.scan(/(\d+)_(.*?)\.pantry$/).first

        if version.to_i > versions.last.to_i
          pantry.classify.constantize.new.use(:file_name => filepath)

          # record successful thing to db
          stmt = table.compile_insert table[:version] => version
          ActiveRecord::Base.connection.insert stmt
        end
      end
    end
  end
end
