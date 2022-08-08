# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileCloning
  include ProfileFields
  include ProfileTailoring
  include ProfileScoring
  include ProfilePolicyAssociation
  include ProfileSearching
  include ProfileHosts
  include ProfileRules
  include ShortRefId

  sortable_by :name, Arel.sql('COALESCE(policies.name, profiles.name)'),
              scope: :joins_policy
  sortable_by :os_minor_version
  sortable_by :score

  belongs_to :account, optional: true
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'
  belongs_to :parent_profile, class_name: 'Profile', optional: true
  has_many :child_profiles, class_name: 'Profile', dependent: :destroy,
                            foreign_key: :parent_profile_id,
                            inverse_of: :parent_profile

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
  validates :account, presence: true, if: -> { parent_profile_id && hosts.any? }
  validates :policy, presence: true, if: -> { policy_id }

  scope :canonical_for_os, lambda { |os_major_version, os_minor_version|
    benchmarks = Xccdf::Benchmark.latest_for_os(
      os_major_version, os_minor_version
    )
    canonical.where(benchmark_id: benchmarks)
  }

  scope :joins_policy, -> { left_outer_joins(:policy) }

  delegate :account_number, to: :account, allow_nil: true
  delegate :org_id, to: :account, allow_nil: true

  class << self
    def from_openscap_parser(op_profile, benchmark_id: nil, account_id: nil)
      profile = find_or_initialize_by(ref_id: op_profile.id,
                                      benchmark_id: benchmark_id,
                                      account_id: account_id)

      profile.assign_attributes(
        name: op_profile.title,
        description: op_profile.description,
        upstream: false
      )

      profile
    end
  end
end
