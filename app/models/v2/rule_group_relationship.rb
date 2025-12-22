# frozen_string_literal: true

module V2
  # Required and conflicting relationships between rules and rule groups
  class RuleGroupRelationship < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :rule_group_relationships_v2
    self.primary_key = :id

    belongs_to :left, polymorphic: true
    belongs_to :right, polymorphic: true

    validates :relationship, presence: true, inclusion: { in: %w[requires conflicts] }

    # Need to use left_id because polymorphic associations don't support computing the class
    validates :left_id, presence: true, uniqueness: { scope: %i[relationship right_id right_type left_type] }
  end
end
