class Pantry::Observer < ActiveRecord::Observer
  def after_create(record)
    after_anything(record, :create)
  end

  def after_update(record)
    after_anything(record)
  end

  def after_destroy(record)
    after_anything(record)
  end
  
  protected  

  def after_anything(record, action = nil)
    define_stacks unless record.respond_to?(:to_pantry)

    pantry_item = record.to_pantry
    
    pantry_item.old_attributes = record.changes.inject({}) { |memo, (k, v)| memo.merge(k => v.first) } unless action == :create

    Pantry::CellarItem.create!(
      :record => record,
      :item => pantry_item.to_json,
      :pantry_type => record.pantry.class.name
    )
  end
  
  def define_stacks
    # hook method for subclasses to define
  end
  
end
