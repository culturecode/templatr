module Templatr
	class Field < ActiveRecord::Base
	  has_many :field_values, :dependent => :destroy
	  has_many :tags, :inverse_of => :field

	  belongs_to :field_group

	  scope :common, where(:template_id => nil)
	  scope :specific, where("template_id IS NOT NULL")
	  scope :common_or_specific_type, lambda {|type| where("template_id IS NULL OR template_id = ?", type.id) }
	  scope :show_tag_cloud, where('show_tag_cloud').order('"order" ASC, id ASC')
	  scope :included_in_item_list, where('include_in_item_list').order('"order" ASC, id ASC')
	  scope :with_name, lambda {|name| where("LOWER(name) = LOWER(?) ", name) }

	  def self.search_suggestions(value = true); where(:search_suggestions => value); end

	  def self.templatable_class
	    self.to_s.gsub(/Field\Z/, '').constantize
	  end

	  # Reserved field names that the user is not allowed to use
	  # "Type" is reserved to differentiate between Templates
	  def self.reserved_fields
	    [:type] + templatable_class.attribute_names.collect(&:to_sym) + templatable_class.reflect_on_all_associations.collect(&:name)
	  end

	  def self.valid_field_types
	    %w(string text float integer boolean integer_with_uncertainty select_one select_multiple)
	  end

	  # The valid ways to migrate data between field types
	  def self.valid_migration_paths
	    { :string          => [:select_one, :select_multiple, :text],
	      :select_one      => [:string, :select_multiple, :text]
	    }.with_indifferent_access
	  end

	  def self.valid_migration_path?(from, to)
	    paths = valid_migration_paths[from]
	    paths && paths.include?(to.to_sym)
	  end

	  def valid_migration_paths
	    new_record? ? self.class.valid_field_types : [self.field_type] + Array(self.class.valid_migration_paths[self.field_type])
	  end

	  accepts_nested_attributes_for :field_values, :allow_destroy => true, :reject_if => :all_blank

	  validates_inclusion_of :field_type, :in => valid_field_types

	  validates_presence_of :name
	  validate :has_unique_name
	  validates_exclusion_of :name, :in => lambda {|f| CSVSerializer.han(f.class.templatable_class, f.class.reserved_fields, :downcase => true) }

	  after_save :disambiguate_fields, :migrate_field_type
	  after_destroy :disambiguate_fields

	  def string?;                   field_type == 'string' end
	  def text?;                     field_type == 'text' end
	  def boolean?;                  field_type == 'boolean' end
	  def float?;                    field_type == 'float' end
	  def integer?;                  field_type == 'integer' end
	  def integer_with_uncertainty?; field_type == 'integer_with_uncertainty' end
	  def select?;                   field_type == 'select_one' || field_type == 'select_multiple' end
	  def select_one?;               field_type == 'select_one' end
	  def select_multiple?;          field_type == 'select_multiple' end

	  def to_s
	    self.name
	  end

	  def common?
	    template_id.nil?
	  end

	  def facet?
	    include_in_search_form? || search_suggestions?
	  end

	  # Don't allow changes to the type if the field is saved
	  def can_change_type?
	    new_record? || self.class.valid_migration_paths[self.field_type].present?
	  end

	  def scalar?
	    string? || text? || boolean? || float? || integer? || integer_with_uncertainty?
	  end

	  def vector?
	    !scalar?
	  end

	  # Coerce the field_type to a string at all times so testing for it is easier
	  def field_type=(value)
	    super(value.to_s)
	  end

	  # GLINT INTEGRATION

	  # What attribute type should glint use to store this field's values
	  def attribute_type
	    (float? || integer? || text? || boolean? ? field_type : 'string').to_sym
	  end

	  def facet_name
	    :"field_#{id}"
	  end

	  def param
	    (self.disambiguate? ? "#{template.name} #{self.name}" : self.name).downcase # param is always case insensitive
	  end

	  private

	  def migrate_field_type
	    return unless field_type_changed? && field_type_was.present?

	    if self.class.valid_migration_path?(field_type_was, self.field_type)
	      new_field_type = self.field_type
	      self.field_type = field_type_was

	      tags.collect do |tag|
	        [tag, tag.value]
	      end.tap do
	        self.field_type = new_field_type
	      end.each do |tag, old_value|
	        tag.value = old_value
	        tag.save!
	      end

	      # Unhook the old field values
	      unless select?
	        tags.each do |tag|
	          tag.update_attribute(:field_value, nil)
	          tag.field_values = []
	        end
	        field_values.destroy_all
	      end
	    else
	      raise "Can't convert from a #{field_type_was} to #{field_type} field"
	    end
	  end

	  def has_unique_name
	    scope = self.class.where("LOWER(name) = LOWER(?)", self.name)
	    scope = scope.where("id != ?", self.id) if self.id
	    scope = scope.where(:template_id => [nil, self.template_id]) if self.template_id

	    errors.add(:name, "has already been taken") if scope.exists?
	  end

	  # Finds all fields with the same name and ensures they know there is another field with the same name
	  # thus allowing us to have them a prefix that lets us identify them in a query string
	  def disambiguate_fields
	    if name_changed? # New, Updated
	      fields = self.class.specific.where("LOWER(name) = LOWER(?)", self.name)
	      fields.update_all(:disambiguate => fields.many?)
	    end

	    if name_was # Updated, Destroyed
	      fields = self.class.specific.where("LOWER(name) = LOWER(?)", self.name_was)
	      fields.update_all(:disambiguate => fields.many?)
	    end
	  end

	  # END GLINT INTEGRATION
	end
end
