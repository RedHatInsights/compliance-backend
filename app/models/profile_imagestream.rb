# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and Host
class ProfileImagestream < ApplicationRecord
  belongs_to :profile
  belongs_to :imagestream

  validates :profile, presence: true
  validates :imagestream, presence: true, uniqueness: { scope: :profile }
end
