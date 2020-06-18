# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileTailoring
  include ProfileScoring
  include ProfilePolicyAssociation
  include ProfileSearching

  has_many :profile_rules, dependent: :delete_all
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :destroy
  has_many :hosts, through: :profile_hosts, source: :host
  has_many :test_results, dependent: :destroy
  belongs_to :account, optional: true
  belongs_to :business_objective, optional: true
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'
  belongs_to :parent_profile, class_name: 'Profile', optional: true

  validates :ref_id, uniqueness: { scope: %i[account_id benchmark_id] },
                     presence: true
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
    else
      new_profile.hosts << host unless new_profile.hosts.include?(host)
    end
    new_profile.update_rules(ref_ids: rules.pluck(:ref_id))
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

  def update_rules(ids: nil, ref_ids: nil)
    ids_to_add = rule_ids_to_add(ids, ref_ids)

    ProfileRule.where(rule_id: rule_ids - ids_to_add, profile_id: id)
               .destroy_all

    ProfileRule.import!(ids_to_add.map do |rule|
      ProfileRule.new(profile_id: id, rule_id: rule.id)
    end)
  end

  private

  def rule_ids_to_add(ids, ref_ids)
    bm_rules = benchmark.rules.select(:id).where.not(id: rule_ids)

    rel = if ids
            bm_rules.where(id: ids)
          elsif ref_ids
            bm_rules.where(ref_id: ref_ids)
          end

    rel&.any? ? rel : bm_rules.where(id: parent_profile_rule_ids)
  end

  def parent_profile_rule_ids
    parent_profile&.rules&.select(:id) || []
  end
end
