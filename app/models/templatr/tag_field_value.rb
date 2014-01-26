module Templatr
	class TagFieldValue < ActiveRecord::Base
	  belongs_to :field_value
	  belongs_to :tag
	end
end
