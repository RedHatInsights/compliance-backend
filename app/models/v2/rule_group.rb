# frozen_string_literal: true

module V2
  # Stores information about Rule Groups. This (eventually) comes from SCAP import.
  class RuleGroup < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_rule_groups
    self.primary_key = :id

    belongs_to :security_guide

    has_ancestry primary_key_format: %r{\A[\w\-]+(\/[\w\-]+)*\z}
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy

    sortable_by :precedence

    searchable_by :title, %i[like unlike eq ne]
    searchable_by :ref_id, %i[like unlike]

    def self.from_parser(obj, existing: nil, security_guide_id: nil, parent_id: nil, precedence: nil)
      record = existing || new(ref_id: obj.id, security_guide_id: security_guide_id)

      record.assign_attributes(title: obj.title, description: obj.description, rationale: obj.rationale,
                               precedence: precedence, parent_id: parent_id)

      record
    end
  end
end
