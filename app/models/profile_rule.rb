# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and Rule
class ProfileRule < ApplicationRecord
  # FIXME: V2 compatibility - clean up after V2 report parsing refactor
  self.table_name = :v1_profile_rules
  self.primary_key = :id

  belongs_to :profile
  belongs_to :rule

  validates :profile, presence: true
  validates :rule, presence: true, uniqueness: { scope: :profile }
end
