require "templatr/engine"

module Templatr
  def self.merge_duplicate_field_values
    FieldValue.duplicated_field_values.find_each do |field_value|
      duplicate_field_values = FieldValue.where(field_value.attributes.slice('field_id', 'value')).where('id != ?', field_value)
      Tag.where(field_value_id: duplicate_field_values).update_all(field_value_id: field_value)
      TagFieldValue.where(field_value_id: duplicate_field_values).update_all(field_value_id: field_value)
      duplicate_field_values.destroy_all
    end
  end
end
