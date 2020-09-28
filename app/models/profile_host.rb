# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and Host
class ProfileHost < ApplicationRecord
  belongs_to :profile
  belongs_to :host

  validates :profile, presence: true
  validates :host, presence: true, uniqueness: { scope: :profile }

  after_destroy :destroy_orphaned_external_profile

  def destroy_orphaned_external_profile
    return unless profile.external && profile.hosts.empty?

    profile.destroy
  end
end
