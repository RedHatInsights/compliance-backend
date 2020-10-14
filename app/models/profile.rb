# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileTailoring
  include ProfileScoring
  include ProfilePolicyAssociation
  include ProfileSearching
  include ProfileHosts
  include ProfileRules

  has_many :test_results, dependent: :destroy
  belongs_to :account, optional: true
  belongs_to :business_objective, optional: true
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'
  belongs_to :parent_profile, class_name: 'Profile', optional: true

  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id external]
  }, presence: true
  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id policy_id]
  }, presence: true
  validates :name, presence: true
  validates :benchmark_id, presence: true
  validates :compliance_threshold, numericality: true
  validates :account, presence: true, if: -> { hosts.any? }

  after_update :destroy_orphaned_business_objective
  after_rollback :destroy_orphaned_business_objective

  class << self
    def from_openscap_parser(op_profile, benchmark_id: nil, account_id: nil)
      profile = find_or_initialize_by(
        ref_id: op_profile.id,
        benchmark_id: benchmark_id,
        account_id: account_id
      )

      profile.assign_attributes(
        name: op_profile.title,
        description: op_profile.description
      )

      profile
    end
  end

  def fill_from_parent
    self.ref_id = parent_profile.ref_id
    self.benchmark_id = parent_profile.benchmark_id
    self.name ||= parent_profile.name
    self.description ||= parent_profile.description

    self
  end

  def canonical?
    parent_profile_id.blank?
  end

  def destroy_orphaned_business_objective
    bo_changes = (previous_changes.fetch(:business_objective_id, []) +
                  changes.fetch(:business_objective_id, [])).compact
    return if bo_changes.blank?

    BusinessObjective.without_profiles.where(id: bo_changes).destroy_all
  end

  def clone_to(account: nil, host: nil, external: true)
    new_profile = in_account(account)
    if new_profile.nil?
      (new_profile = dup).update!(account: account, hosts: [host],
                                  parent_profile: self,
                                  external: external)
      new_profile.update_rules(ref_ids: rules.pluck(:ref_id))
    else
      new_profile.hosts << host unless new_profile.hosts.include?(host)
    end

    new_profile
  end

  def in_account(account)
    Profile.find_by(account: account, ref_id: ref_id,
                    benchmark_id: benchmark_id)
  end

  def major_os_version
    benchmark ? benchmark.inferred_os_major_version : 'N/A'
  end
  alias os_major_version major_os_version

  def short_ref_id
    ref_id.downcase.split(
      'xccdf_org.ssgproject.content_profile_'
    )[1] || ref_id
  end
end
