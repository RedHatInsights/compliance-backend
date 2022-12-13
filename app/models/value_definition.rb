# frozen_string_literal: true

# Stores information about value definitions. This comes from SCAP.
class ValueDefinition < ApplicationRecord
  include OpenscapParserDerived

  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'

  POSSIBLE_VALUE_TYPES = %w[string number boolean].freeze

  validates :benchmark_id, presence: true
  validates :ref_id, uniqueness: { scope: %i[benchmark_id] }, presence: true
  validates :description, presence: true
  validates :value_type, presence: true, inclusion: { in: POSSIBLE_VALUE_TYPES }

  def self.from_openscap_parser(op_vd, existing: nil, benchmark_id: nil)
    value_definition = existing || new(ref_id: op_vd.id, benchmark_id: benchmark_id)

    value_definition.op_source = op_vd

    value_definition.assign_attributes(title: op_vd.title, description: op_vd.description,
                                       value_type: op_vd.type, default_value: op_vd.value)

    value_definition
  end
end
