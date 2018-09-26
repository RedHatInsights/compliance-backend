# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and Rule
class ProfileRule < ApplicationRecord
  belongs_to :profile
  belongs_to :rule

  validates :profile, presence: true
  validates :rule, presence: true, uniqueness: { scope: :profile }
end
