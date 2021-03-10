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
    scope: %i[account_id benchmark_id os_minor_version policy_id],
    message: 'must be unique in a policy OS version'
  }, presence: true
  validates :ref_id, uniqueness: {
    scope: %i[account_id benchmark_id],
    conditions: -> { where(external: false) },
    message: 'must be unique for an internal profile'
  }, unless: :external
  validates :external, uniqueness: {
    scope: %i[ref_id account_id benchmark_id],
    conditions: -> { where(policy_id: nil) }
  }, unless: :policy_id
  validates :os_minor_version, uniqueness: {
    scope: %i[account_id policy_id]
  }, if: -> { os_minor_version.present? }
  validates :name, presence: true
  validates :benchmark_id, presence: true
  validates :account, presence: true, if: -> { hosts.any? }
  validates :policy, presence: true, if: -> { policy_id }

  scope :canonical_for_os, lambda { |os_major_version, os_minor_version|
    canonical.ssg_versions(
      SupportedSsg.latest_ssg_version_for_os(os_major_version, os_minor_version)
    ).os_major_version(os_major_version)
  }

  delegate :account_number, to: :account, allow_nil: true

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

  def ssg_version
    benchmark.version
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

  def clone_to(account:, policy:, os_minor_version: nil)
    new_profile = in_account(account, policy)
    if new_profile.nil?
      (new_profile = dup).update!(account: account,
                                  parent_profile: self,
                                  external: true,
                                  policy: policy)
      new_profile.update_rules(ref_ids: rules.pluck(:ref_id))
    end

    # Update the os minor version if not already set
    new_profile.update_os_minor_version(os_minor_version)

    new_profile
  end

  def major_os_version
    benchmark&.inferred_os_major_version
  end
  alias os_major_version major_os_version

  def os_version
    "#{os_major_version}#{'.' + os_minor_version if os_minor_version.present?}"
  end

  def short_ref_id
    ref_id.downcase.split(
      'xccdf_org.ssgproject.content_profile_'
    )[1] || ref_id
  end

  def update_os_minor_version(version)
    update!(os_minor_version: version) if version && os_minor_version.empty?
  end

  private

  def in_account(account, policy)
    Profile.find_by(account: account, ref_id: ref_id,
                    policy: policy,
                    benchmark_id: benchmark_id)
  end
end
