# frozen_string_literal: true

module V2
  # Stores information about Rule Groups. This (eventually) comes from SCAP import.
  class RuleGroup < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :rule_groups_v2
    self.primary_key = :id

    belongs_to :security_guide

    has_ancestry primary_key_format: %r{\A[\w\-]+(\/[\w\-]+)*\z}
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy

    sortable_by :precedence

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :ref_id, %i[like unlike]
  end
end
