# frozen_string_literal: true

# Stores information about value definitions. This comes from SCAP.
module V2
  # Model for Value Definitions
  class ValueDefinition < ApplicationRecord
    # FIXME: drop the foreign key and alias after remodel
    alias_attribute :security_guide_id, :benchmark_id
    belongs_to :security_guide, class_name: 'V2::SecurityGuide', foreign_key: 'benchmark_id', inverse_of: false

    sortable_by :title

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
  end
end
