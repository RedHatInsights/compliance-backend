# frozen_string_literal: true

# Stores information about rules. This comes from SCAP.
module V2
  # Model for Rules
  class Rule < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_rules
    self.primary_key = :id

    SORTED_SEVERITIES = Arel.sql(
      AN::Case.new.when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('high'))
      ).then(3).when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('medium'))
      ).then(2).when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('low'))
      ).then(1).else(0).to_sql
    )

    belongs_to :security_guide

    sortable_by :title
    sortable_by :severity, SORTED_SEVERITIES
    sortable_by :precedence

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: :severity, only_explicit: true, operators: %i[eq ne in notin]
  end
end
