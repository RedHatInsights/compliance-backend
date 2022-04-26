# frozen_string_literal: true

# Join table between Policy and Host
class PolicyHost < ApplicationRecord
  belongs_to :policy
  belongs_to :host, optional: true

  validates :policy, presence: true
  validates :host, presence: true, on: :create
  validates :host_id, presence: true, uniqueness: { scope: :policy }
  validate :host_supported?, on: :create

  def self.import_from_policy!(policy_id, host_ids)
    import!(host_ids.map do |host_id|
      { host_id: host_id, policy_id: policy_id }
    end)
  end

  private

  def host_supported?
    if !os_major_supported?
      errors.add(:host, 'Unsupported OS major version')
    elsif !os_minor_supported?
      errors.add(:host, 'Unsupported OS minor version')
    end
  end

  def os_major_supported?
    !host&.os_major_version.nil? && host&.os_major_version.to_s == policy&.initial_profile&.os_major_version.to_s
  end

  def os_minor_supported?
    policy&.supported_os_minor_versions&.include?(host&.os_minor_version.to_s)
  end
end
