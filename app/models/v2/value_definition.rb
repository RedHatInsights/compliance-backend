# frozen_string_literal: true

# Stores information about value definitions. This comes from SCAP.
module V2
  # Model for Value Definitions
  class ValueDefinition < ApplicationRecord
    # FIXME: clean up after the remodel
    self.primary_key = :id
    self.table_name = :v2_value_definitions

    belongs_to :security_guide

    sortable_by :title

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :ref_id, %i[like unlike]

    attr_accessor :op_source

    def validate_value(value)
      return false unless value.is_a?(String)

      case value_type
      when 'boolean'
        %w[true false].include?(value)
      when 'number'
        value.to_i.to_s == value # FIXME: lower/upper bound validation if it's ever used
      when 'string'
        true
      end
    end

    def self.from_parser(obj, existing: nil, security_guide_id: nil)
      record = existing || new(ref_id: obj.id, security_guide_id: security_guide_id)
      record.op_source = obj
      record.assign_attributes(title: obj.title, description: obj.description,
                               value_type: obj.type, default_value: obj.value)
      record
    end
  end
end
