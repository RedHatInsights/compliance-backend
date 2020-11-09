# frozen_string_literal: true

# Compliance policy
class Policy < ApplicationRecord
  DEFAULT_COMPLIANCE_THRESHOLD = 100.0
  PROFILE_ATTRS = %w[name description account_id compliance_threshold
                     business_objective_id].freeze

  has_many :profiles, dependent: :destroy, inverse_of: :policy_object
  has_many :benchmarks, through: :profiles
  has_many :test_results, through: :profiles, dependent: :destroy

  has_many :policy_hosts, dependent: :destroy
  has_many :hosts, through: :policy_hosts, source: :host

  belongs_to :business_objective, optional: true
  belongs_to :account

  validates :compliance_threshold, numericality: true
  validates :account, presence: true
  validates :name, presence: true

  after_destroy :destroy_orphaned_business_objective
  after_update :destroy_orphaned_business_objective
  after_rollback :destroy_orphaned_business_objective

  def self.attrs_from(profile:)
    profile.attributes.slice(*PROFILE_ATTRS)
  end

  def fill_from(profile:)
    self.name ||= profile.name
    self.description ||= profile.description

    self
  end

  def update_hosts(new_host_ids)
    return unless new_host_ids

    policy_hosts.where.not(host_id: new_host_ids).destroy_all
    PolicyHost.import((new_host_ids - host_ids).map do |host_id|
      { host_id: host_id, policy_id: id }
    end)
  end

  def os_major_version
    benchmarks.first.os_major_version
  end

  def initial_profile
    # assuming that there is only one external=false profile in a policy
    profiles.external(false).first
  end

  def destroy_orphaned_business_objective
    bo_changes = (previous_changes.fetch(:business_objective_id, []) +
                  changes.fetch(:business_objective_id, []) +
                  [business_objective_id]).compact
    BusinessObjective.without_policies.where(id: bo_changes).destroy_all
  end
end
