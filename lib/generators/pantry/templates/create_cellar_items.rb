class CreateCellarItems < ActiveRecord::Migration
  def change
    create_table :cellar_items do |t|
      t.belongs_to :record, :polymorphic => true
      t.text :item
      t.string :pantry_type
      t.datetime :stacked_at
      t.timestamps
    end

    create_table :cellar_migrations, :id => false do |t|
      t.string :version, :null => false
    end

    add_index :cellar_migrations, :version, :unique => true
  end
end
