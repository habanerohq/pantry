class Pantry::Observer < ActiveRecord::Observer
  def after_create(record)
    Pantry::CellarItem.create!(
      :record => record,
      :item => record.to_pantry.to_json,
      :pantry_type => 'SorbetPantry'
    )
  end

  def after_update(record)
    pantry_item = record.to_pantry
    pantry_item.old_attributes = record.changes.inject({}) { |memo, (k, v)| memo.merge(k => v.first) }

    Pantry::CellarItem.create!(
      :record => record,
      :item => pantry_item.to_json,
      :pantry_type => 'SorbetPantry'
    )
  end

  def after_destroy(record)
    # todo: how to delete pantry item
  end
end
