# frozen_string_literal: true

# Join table between Policy and Host
class PolicyHost < ApplicationRecord
  belongs_to :policy
  belongs_to :host, optional: true

  validates :policy, presence: true
  validates :host, presence: true, on: :create
  validates :host_id, presence: true, uniqueness: { scope: :policy }
  validate :host_supported?, on: :create

  class << self
    def import_from_policy!(policy_id, host_ids)
      hosts = Host.where(id: host_ids).distinct
      # Policy#find raises an exception if the record is not found
      policy = Policy.find(policy_id)

      # Bypass the validation if there are no hosts to be assigned
      if hosts.any? && (!os_major_supported?(policy, hosts) || !os_minors_supported?(policy, hosts))
        raise ActiveRecord::RecordInvalid.new(policy), 'Unsupported OS version in one of the hosts'
      end

      import(host_ids.map do |host_id|
        { host_id: host_id, policy_id: policy_id }
      end, validate: false, validate_uniqueness: true)
    end

    private

    def os_major_supported?(policy, hosts)
      os_major_version = hosts.distinct.pluck(Host::OS_MAJOR_VERSION)

      return false if os_major_version.size != 1

      os_major_version.first.to_s == policy&.initial_profile&.os_major_version&.to_s
    end

    def os_minors_supported?(policy, hosts)
      os_minor_versions = hosts.pluck(Host::OS_MINOR_VERSION).map(&:to_s)
      (os_minor_versions & policy&.supported_os_minor_versions&.uniq).size == os_minor_versions.size
    end
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
