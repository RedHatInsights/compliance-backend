# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileFields
  include ProfileTailoring
  include ProfileScoring
  include ProfilePolicyAssociation
  include ProfileSearching
  include ProfileHosts
  include ProfileRules

  SORTABLE_BY = {
    name: Arel.sql('LOWER(name)'),
    os_minor_version: :os_minor_version
  }.freeze

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
  validates :account, presence: true, if: -> { hosts.any? }
  validates :policy, presence: true, if: -> { policy_id }

  scope :canonical_for_os, lambda { |os_major_version, os_minor_version|
    benchmarks = Xccdf::Benchmark.latest_for_os(
      os_major_version, os_minor_version
    )
    canonical.where(benchmark_id: benchmarks)
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

  def fill_from_parent
    self.ref_id = parent_profile.ref_id
    self.benchmark_id = parent_profile.benchmark_id
    self.name ||= parent_profile.name
    self.description ||= parent_profile.description

    self
  end

  def clone_to(account:, policy:,
               os_minor_version: nil, set_os_minor_version: nil)
    new_profile = in_account(
      account, policy,
      os_minor_version || set_os_minor_version
    )
    new_profile ||= create_child_profile(account, policy)

    if set_os_minor_version
      # Update the os minor version if not already set
      new_profile.update_os_minor_version(set_os_minor_version)
    end
    new_profile
  end

  private

  def create_child_profile(account, policy)
    new_profile = dup
    new_profile.update!(account: account, parent_profile: self,
                        external: true, policy: policy)
    new_profile.update_rules(ref_ids: rules.pluck(:ref_id))

    Rails.logger.audit_success(%(
      Created profile #{new_profile.id} from canonical profile #{id}
      under policy #{policy&.id}
    ).gsub(/\s+/, ' ').strip)

    new_profile
  end
end
