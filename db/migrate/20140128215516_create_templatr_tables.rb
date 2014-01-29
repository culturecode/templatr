class CreateTemplatrTables < ActiveRecord::Migration
  def change
		create_table :templatr_field_groups, :force => true do |t|
	    t.string :name
	  end

	  create_table :templatr_field_values, :force => true do |t|
	    t.integer :field_id
	    t.string  :value
	    t.text    :description
	  end

	  create_table :templatr_fields, :force => true do |t|
	    t.integer  :template_id, :index => true
	    t.string   :name
	    t.string   :field_type
	    t.integer  :order
	    t.integer  :field_group_id
	    t.datetime :created_at
	    t.datetime :updated_at
	    t.boolean  :search_suggestions,     :default => false, :null => false
	    t.boolean  :include_in_search_form, :default => false, :null => false
	    t.boolean  :include_in_item_list,   :default => false, :null => false
	    t.boolean  :show_tag_cloud,         :default => false, :null => false
	    t.string   :type
	    t.boolean  :disambiguate,           :default => false, :null => false
	  end

	  create_table :templatr_tag_field_values, :force => true do |t|
	    t.integer :tag_id
	    t.integer :field_value_id
	  end

	  create_table :templatr_tags, :force => true do |t|
	    t.integer :taggable_id, :index => true
	    t.string  :name
	    t.integer :field_id
	    t.integer :field_value_id
	    t.integer :integer_value
	    t.float   :float_value
	    t.text    :text_value
	    t.string  :string_value
	    t.date    :date_value
	    t.integer :integer_value_uncertainty
	    t.boolean :boolean_value
	    t.string  :type
	  end

	  create_table :templatr_templates, :force => true do |t|
	    t.string :name
	    t.string :type
	  end
	end
end
