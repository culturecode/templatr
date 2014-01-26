# encoding: UTF-8
module Templatr
  class Tag < ActiveRecord::Base
    belongs_to :field, :inverse_of => :tags

    # Select
    belongs_to :field_value

    # Select Multiple
    has_many :tag_field_values, :dependent => :destroy
    has_many :field_values, :through => :tag_field_values

    delegate :scalar?, :vector?, :string?, :text?, :select_one?, :select_multiple?, :boolean?, :float?, :integer?, :integer_with_uncertainty?, :to => :field

    before_validation :mark_for_destruction_if_blank

    attr_writer :value # Allows the setting and getting of the value, before it has been persisted
    before_save :persist_value

    def self.templatable_class
      self.to_s[/[A-Z][a-z]+/].constantize
    end

    def custom_tag?
      !field
    end

    def name
      custom_tag? ? self['name'] : field.name
    end

    def value
      if !@value.nil?
        @value
      elsif custom_tag? || string?
        string_value
      elsif text?
        text_value
      elsif select_one?
        field_value.to_s
      elsif select_multiple?
        field_values.collect(&:to_s)
      elsif boolean?
        boolean_value
      elsif float?
        float_value
      elsif integer?
        integer_value
      elsif integer_with_uncertainty?
        _value = integer_value.to_s
        _value << " ± #{integer_value_uncertainty}" if integer_value_uncertainty
        _value
      else
        raise "Unknown Field Type: #{field.field_type.inspect}"
      end
    end

    def to_s
      value.is_a?(Array) ? value.join(', ') : value
    end

    def field_group_id
      field.field_group_id if field
    end

    # Allow field value to be set by passing a string
    def field_value=(value)
      super find_or_create_field_value(value)
    end

    # Allow field value to be set by passing a string
    def field_values=(value)
      super Array.wrap(value).collect {|value| find_or_create_field_value(value) }
    end

    private

    def find_or_create_field_value(value)
      case value
      when String
        field.field_values.where(:value => value).first_or_create!
      else
        value
      end
    end

    def persist_value
      if custom_tag? || string?
        self.string_value = @value.to_s # Ensure that if an AR object is passed, it doesn't turn into the record id
      elsif text?
        self.text_value = @value.to_s
      elsif select_one?
        self.field_value = @value
      elsif select_multiple?
        self.field_values = @value
      elsif boolean?
        self.boolean_value = @value
      elsif float?
        self.float_value = @value.to_s
      elsif integer?
        self.integer_value = @value.to_s
      elsif integer_with_uncertainty?
        self.integer_value = @value.first.to_s
        self.integer_value_uncertainty = @value.second
      else
        raise "Unknown Field Type: #{field.field_type.inspect}"
      end

      puts "persisted value '#{value}'"

      return true # Ensure that if we set a value to false we don't accidentally cancel the save
    end

    def mark_for_destruction_if_blank
      # Tell the parent object to delete this tag when saving if it is a nil value
      # NOTE: Boolean's false value evaluates to blank, but should be interpreted as present
      @marked_for_destruction = (boolean? ? self.value.nil? : self.value.blank?).presence
    end
  end
end
