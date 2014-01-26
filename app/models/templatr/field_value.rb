module Templatr
  class FieldValue < ActiveRecord::Base
    belongs_to :field

    has_many :tag_field_values # Don't need to destroy this because tags will take care of the link tables

    validates_presence_of :field_id, :value

    def to_s
      self.value
    end
  end
end
