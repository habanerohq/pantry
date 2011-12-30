class CreateTestModels < ActiveRecord::Migration
  def up
    create_table :describeds, :force => true do |t|
      t.string   :descriptor
      t.string   :value
      t.timestamps
    end
    create_table :nameds, :force => true do |t|
      t.string   :name
      t.string   :value
      t.timestamps
    end
    create_table :labelleds, :force => true do |t|
      t.string   :name
      t.string   :value
      t.timestamps
    end
    create_table :valueds, :force => true do |t|
      t.string   :value
      t.timestamps
    end
    create_table :composites, :force => true do |t|
      t.string   :some_identifying_value
      t.references :whole, :owner
      t.string :owner_type
      t.timestamps
    end
  end

  def down
  end
end
