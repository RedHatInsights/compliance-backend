# frozen_string_literal: true

# Required and conflicting relationships between rules and rule groups
class RuleGroupRelationship < ApplicationRecord
  # FIXME: V2 compatibility - clean up after V2 report parsing refactor
  self.table_name = :v1_rule_group_relationships
  self.primary_key = :id

  belongs_to :left, polymorphic: true
  belongs_to :right, polymorphic: true

  validates :relationship, presence: true, inclusion: { in: %w[requires conflicts] }

  # Need to use left_id because polymorphic assocations don't support computing the class
  validates :left_id, presence: true, uniqueness: { scope: %i[relationship right_id right_type left_type] }
end
