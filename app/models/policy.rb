# frozen_string_literal: true

# Compliance policy
class Policy < ApplicationRecord
  include ProfilePolicyScoring

  DEFAULT_COMPLIANCE_THRESHOLD = 100.0
  PROFILE_ATTRS = %w[name description account_id].freeze

  has_many :profiles, dependent: :destroy, inverse_of: :policy
  has_many :benchmarks, through: :profiles
  has_many :test_results, through: :profiles, dependent: :destroy

  has_many :policy_hosts, dependent: :delete_all
  has_many :hosts, through: :policy_hosts, source: :host
  has_many :test_result_hosts, through: :test_results, source: :host

  belongs_to :business_objective, optional: true
  belongs_to :account
  delegate :org_id, to: :account

  validates :compliance_threshold, numericality: true
  validates :account, presence: true
  validates :name, presence: true

  after_destroy :destroy_orphaned_business_objective
  after_update :destroy_orphaned_business_objective
  after_rollback :destroy_orphaned_business_objective

  scope :with_hosts, lambda { |hosts|
    joins(:hosts).where(hosts: { id: hosts }).distinct
  }

  scope :with_ref_ids, lambda { |ref_ids|
    joins(:profiles).where(profiles: { ref_id: ref_ids }).distinct
  }

  def self.attrs_from(profile:)
    profile.attributes.slice(*PROFILE_ATTRS)
  end

  def fill_from(profile:)
    self.name ||= profile.name
    self.description ||= profile.description

    self
  end

  def update_hosts(new_host_ids, user)
    return unless new_host_ids

    # Remove only those assigned hosts, which are accessible by the user
    removed = Pundit.policy_scope(user, PolicyHost)
                    .where.not(host_id: new_host_ids).destroy_all

    # The new hosts are already scoped down for the user
    imported = PolicyHost.import_from_policy!(id, new_host_ids - host_ids)
    update_os_minor_versions
    # FIXME: this needs to go as each user will have their own counters
    update_counters!

    [imported.ids.count, removed.count]
  end

  def update_os_minor_versions
    unassigned_minor_versions.each do |os_minor_version|
      Profile.canonical_for_os(
        initial_profile.os_major_version, os_minor_version
      ).find_by(ref_id: initial_profile.ref_id)&.clone_to(
        account: account,
        set_os_minor_version: os_minor_version,
        policy: self
      )
    end
  end

  def compliant?(host)
    score(host: host) >= compliance_threshold
  end

  def os_major_version
    benchmarks.first.os_major_version
  end

  def initial_profile
    # there is only one internal (external=false) profile in a policy
    profiles.external(false).first
  end

  def destroy_orphaned_business_objective
    bo_changes = (previous_changes.fetch(:business_objective_id, []) +
                  changes.fetch(:business_objective_id, []) +
                  [business_objective_id]).compact
    removed_bos = BusinessObjective.without_policies
                                   .where(id: bo_changes)
                                   .destroy_all
    audit_bo_autoremove(removed_bos)
  end

  def supported_os_minor_versions
    profile_os_major_version = initial_profile.os_major_version
    Xccdf::Benchmark.including_profile(initial_profile).flat_map do |bm|
      SupportedSsg.by_ssg_version[bm.version]
                  .select { |ssg| ssg.os_major_version == profile_os_major_version }
                  .map(&:os_minor_version)
    end
  end

  private

  def unassigned_minor_versions
    stored_versions = profiles.pluck(:os_minor_version)
    Host.os_minor_versions(hosts).reject do |version|
      # Ignore already stored minor versions
      stored_versions.include?(version.to_s)
    end
  end

  def audit_bo_autoremove(removed_bos)
    return if removed_bos.empty?

    msg = 'Autoremoved orphaned Business Objectives: '
    msg += removed_bos.map(&:id).join(', ')
    Rails.logger.audit_success(msg)
  end
end
