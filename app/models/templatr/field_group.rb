module Templatr
	class FieldGroup < ActiveRecord::Base
	  has_many :fields
	end
end
