class Pantry::Observer < ActiveRecord::Observer
  def after_create(record)
    Pantry::CellarItem.create!(
      :record => record,
      :item => record.to_pantry.to_json,
      :pantry_type => 'SorbetPantry'
    )
  end

  def after_update(record)
    # todo: store old values in pantry item
    Pantry::CellarItem.create!(
      :record => record,
      :item => record.to_pantry.to_json,
      :pantry_type => 'SorbetPantry'
    )
  end

  def after_destroy(record)
    # todo: how to delete pantry item
  end
end
