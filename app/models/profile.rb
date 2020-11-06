# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileTailoring
  include ProfileScoring
  include ProfilePolicyAssociation
  include ProfileSearching
  include ProfileHosts
  include ProfileRules

  belongs_to :account, optional: true
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'
  belongs_to :parent_profile, class_name: 'Profile', optional: true

  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id external policy_id]
  }, presence: true
  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id policy_id],
    message: 'must be unique in a policy'
  }, if: :policy_id
  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id],
    conditions: -> { where(external: false) },
    message: 'must be unique for an internal profile'
  }, unless: :external
  validates :external, uniqueness: {
    scope: %i[ref_id account_id benchmark_id],
    conditions: -> { where(policy_id: nil) }
  }, unless: :policy_id
  validates :name, presence: true
  validates :benchmark_id, presence: true
  validates :account, presence: true, if: -> { hosts.any? }

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

  def policy_type
    (parent_profile || self).name
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

  def clone_to(account: nil, host: nil, external: true, policy: nil)
    policy ||= find_policy(hosts: [host], account: account)&.policy_object

    new_profile = in_account(account, policy)
    if new_profile.nil?
      (new_profile = dup).update!(account: account,
                                  parent_profile: self,
                                  external: external,
                                  policy_object: policy)
      new_profile.update_rules(ref_ids: rules.pluck(:ref_id))
    end

    new_profile
  end

  def in_account(account, policy)
    Profile.find_by(account: account, ref_id: ref_id,
                    policy_object: policy,
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
