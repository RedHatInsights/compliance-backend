# frozen_string_literal: true

# Join table between Policy and Host
class PolicyHost < ApplicationRecord
  belongs_to :policy
  belongs_to :host, optional: true

  validates :policy, presence: true
  validates :host, presence: true, on: :create
  validates :host_id, presence: true, uniqueness: { scope: :policy }
  validate :host_supported?, on: :create

  scope :supported_os_versions, lambda { |policy_id, host_os_major_version|
    profile = Profile.find_by(policy_id: policy_id)
    if host_os_major_version.to_s == profile&.os_major_version.to_s
      profile&.supported_minor_versions
    end
  }

  def self.import_from_policy(policy_id, host_ids)
    import(host_ids.map do |host_id|
      { host_id: host_id, policy_id: policy_id }
    end)
  end

  def host_supported?
    if PolicyHost.supported_os_versions(policy&.id, host&.os_major_version).include?(host&.os_minor_version.to_s)
      return
    end

    errors.add(:host, 'os version is unsupported for this policy')
  end
end
