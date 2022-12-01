# frozen_string_literal: true

# Stores information about value definitions. This comes from SCAP.
class ValueDefinition < ApplicationRecord
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'

  POSSIBLE_VALUE_TYPES = %w[string number bool].freeze

  validates :benchmark_id, presence: true
  validates :ref_id, uniqueness: { scope: %i[benchmark_id] }, presence: true
  validates :description, presence: true
  validates :value_type, presence: true, inclusion: { in: POSSIBLE_VALUE_TYPES }
end
