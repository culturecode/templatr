module Templatr
  module ActsAsTemplatable
    module ActMethod
      def acts_as_templatable(options = {})
        extend Templatr::ActsAsTemplatable::ClassMethods
        include Templatr::ActsAsTemplatable::InstanceMethods

        Templatr::ActsAsTemplatable::HelperMethods.create_field_class(self)
        Templatr::ActsAsTemplatable::HelperMethods.create_tag_class(self)
        Templatr::ActsAsTemplatable::HelperMethods.create_template_class(self)

        TagFieldValue.belongs_to tag_class(false).underscore.to_sym, :foreign_key => :tag_id

        FieldValue.has_many tag_class(false).tableize.to_sym, :dependent => :destroy # Destroy all single select tags with this field value
        FieldValue.has_many :"single_value_#{name.tableize}", :source => name.underscore.to_sym, :through => tag_class(false).tableize.to_sym

        FieldValue.has_many :"multi_value_#{tag_class(false).tableize}", :source => tag_class(false).underscore.to_sym, :through => :tag_field_values, :dependent => :destroy # Destroy all multi select tags with this field value
        FieldValue.has_many :"multi_value_#{name.tableize}", :source => name.underscore.to_sym, :through => :"multi_value_#{tag_class(false).tableize}"

        FieldValue.send(:define_method, name.tableize) do
          if field.select_one?
            single_value_items
          elsif field.select_multiple?
            multi_value_items
          end
        end

        class_eval do
          belongs_to :template, :class_name => template_class
          delegate :template_fields, :to => :template

          has_many :tags, :class_name => tag_class, :foreign_key => :taggable_id, :order => 'templatr_tags.name ASC', :dependent => :destroy, :inverse_of => name.underscore.to_sym
          accepts_nested_attributes_for :tags, :allow_destroy => true

          class_attribute :dynamic_facets
          self.dynamic_facets = []
        end
      end
    end

    module ClassMethods
      def template_class(constantize = true)
        klass = "#{self}Template"
        constantize ? klass.constantize : klass
      end

      def field_class(constantize = true)
        klass = "#{self}Field"
        constantize ? klass.constantize : klass
      end

      def tag_class(constantize = true)
        klass = "#{self}Tag"
        constantize ? klass.constantize : klass
      end

      def search_class(constantize = true)
        klass = "#{self}Search"
        constantize ? klass.constantize : klass
      end

      def update_dynamic_facets
        current_dynamic_facets = []

        field_class.find_each do |field|
          facet_name    = field.facet_name
          facet_options = {:attribute_type => field.attribute_type, :multiple => field.select_multiple?, :param => field.param}

          current_dynamic_facets << facet_name

          create_or_update_facet(facet_name, facet_options) do
            tags.detect {|t| t.field_id == field.id }.try(:value) # Detect instead of SQL constrain so we can eager load the tags association
          end
        end

        # Disable all facets that no longer exist
        (dynamic_facets - current_dynamic_facets).each {|facet_name| search_class.disable_facet(facet_name) }

        self.dynamic_facets = current_dynamic_facets
      end

      private

      def create_or_update_facet(facet_name, facet_options, &block)
        unless search_class.facet?(facet_name)
          define_method(facet_name, &block)
        end

        unless search_class.facet?(facet_name) && search_class.registered_facet(facet_name).options.slice(*facet_options.keys) == facet_options
          has_facet facet_name, facet_options
        end
      end
    end

    module InstanceMethods
      # Returns true if the record is still able to choose which template to use
      def can_change_template?
        !persisted? || !template.present?
      end

      def template_tags(options = {})
        existing_tags = tags.joins(:field).reorder('templatr_fields.field_group_id, templatr_fields.order')

        return existing_tags unless options[:include_blank]

        # Add non-populated tags so that they show in the form
        template_fields.collect do |field|
          existing_tags.detect {|tag| tag.field == field } || Tag.new(:field => field)
        end
      end

      def additional_tags
        tags.where("field_id IS NULL")
      end
    end

		module HelperMethods
			def self.create_field_class(templatable_class)
        field_class = create_class(templatable_class.field_class(false), 'Templatr::Field')

        field_class.belongs_to :template, :class_name => templatable_class.template_class(false), :foreign_key => :template_id, :inverse_of => :default_fields

			  field_class.has_many :tags, :class_name => templatable_class.tag_class(false), :foreign_key => :field_id, :dependent => :destroy, :inverse_of => :field
			  field_class.has_many templatable_class.tag_class(false).tableize.to_sym, :through => :tags

        return field_class
      end

      def self.create_tag_class(templatable_class)
        tag_class = create_class(templatable_class.tag_class(false), 'Templatr::Tag')

        tag_class.belongs_to templatable_class.to_s.underscore.to_sym, :foreign_key => :taggable_id, :inverse_of => :tags

        return tag_class
      end

      def self.create_template_class(templatable_class)
        template_class = create_class(templatable_class.template_class(false), 'Templatr::Template')

        template_class.has_many templatable_class.to_s.tableize.to_sym, :foreign_key => :template_id, :dependent => :destroy
        template_class.has_many :default_fields, :class_name => templatable_class.field_class(false), :foreign_key => :template_id, :order => 'templatr_fields.field_group_id, templatr_fields.order, templatr_fields.id', :dependent => :destroy, :inverse_of => :template
        template_class.has_many :common_fields, :class_name => templatable_class.field_class(false), :foreign_key => :template_id, :order => 'templatr_fields.field_group_id, templatr_fields.order, templatr_fields.id', :primary_key => 'common_fields_fake_foreign_key'

        template_class.accepts_nested_attributes_for :default_fields, :common_fields, :allow_destroy => true

        return template_class
      end

      def self.create_class(klass_name, parent_klass)
        class_header = "class ::"
        class_header << klass_name
        class_header << " < #{parent_klass}" if parent_klass

        begin
          klass_name.constantize
          puts "#{klass_name} has already been created"
        rescue => e
          puts "Creating class #{klass_name}"
          eval "#{class_header}; end"
        end

        return klass_name.constantize
      end
    end
  end
end
