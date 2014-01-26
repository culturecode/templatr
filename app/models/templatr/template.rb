module Templatr
  class Template < ActiveRecord::Base
    validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
    validate :unique_field_names

    after_validation :add_field_uniqueness_errors

    def self.templatable_class
      self.to_s[/[A-Z][a-z]+/].constantize
    end

    # Combined common and default fields
    def template_fields
      common_fields + default_fields
    end

    def to_s
      self.name
    end

    # In order to make common fields appear on a new form, we need to make the has_many association think that it should load them from the database
    # We do so by pretending we have a primary key, knowing that it will evaluate to null
    def attribute_present?(attribute)
      attribute.to_s == 'common_fields_fake_foreign_key' ? true : super
    end

    # Ensure all nested attributes for common fields get saved as common fields, and not as template fields
    def common_fields_attributes=(nested_attributes)
      nested_attributes.values.each do |attributes|
        common_field = common_fields.find {|field| field.id.to_s == attributes[:id] && attributes[:id].present? } || common_fields.build
        assign_to_or_mark_for_destruction(common_field, attributes, true, {})
      end
    end

    private

    def unique_field_names
      names = template_fields.reject(&:marked_for_destruction?).collect {|f| f.name.downcase }

      errors.add(:base, "fields aren't unique") if names.uniq!
    end

    # This needs to run after validation because we don't want the child models to clear these errors when they validate
    def add_field_uniqueness_errors
      names = template_fields.reject(&:marked_for_destruction?).collect {|f| f.name.downcase }

      template_fields.each do |field|
        if names.count(field.name.downcase) > 1
          field.errors.add(:name, "has already been taken")
        end
      end
    end
  end
end
