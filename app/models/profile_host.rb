# frozen_string_literal: true

# Join table to be able to have a has-many-belongs-to-many relation between
# Profile and Host
class ProfileHost < ApplicationRecord
  belongs_to :profile
  belongs_to :host

  validates :profile, presence: true
  validates :host, presence: true, uniqueness: { scope: :profile }

  after_destroy :destroy_orphaned_host

  def destroy_orphaned_host
    return unless host.profiles.empty?

    if Settings.async
      DeleteHost.perform_async(id: host.id)
    else
      DeleteHost.new.perform(id: host.id)
    end
  end
end
