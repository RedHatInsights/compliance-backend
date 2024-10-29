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
  end
end
