# frozen_string_literal: true

# Stores information about rules. This comes from SCAP.
module V2
  # Model for Rules
  class Rule < ApplicationRecord
    SORTED_SEVERITIES = Arel.sql(
      AN::Case.new.when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('high'))
      ).then(3).when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('medium'))
      ).then(2).when(
        Rule.arel_table[:severity].eq(AN::Quoted.new('low'))
      ).then(1).else(0).to_sql
    )

    # FIXME: drop the foreign key and alias after remodel
    alias_attribute :security_guide_id, :benchmark_id
    belongs_to :security_guide, class_name: 'V2::SecurityGuide', foreign_key: 'benchmark_id', inverse_of: false

    sortable_by :title
    sortable_by :severity, SORTED_SEVERITIES
    sortable_by :precedence

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: :severity, only_explicit: true, operators: %i[eq ne in notin]
  end
end
