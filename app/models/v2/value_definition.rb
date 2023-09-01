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

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
  end
end
