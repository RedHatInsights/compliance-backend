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

  scope :canonical, lambda { |canonical = true|
    canonical && where(parent_profile_id: nil) ||
      where.not(parent_profile_id: nil)
  }
  scope :external, lambda { |external = true|
    where(external: external)
  }

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
    self.ref_id ||= parent_profile.ref_id
    self.name ||= parent_profile.name
    self.description ||= parent_profile.description
    self.benchmark_id ||= parent_profile.benchmark_id
    self.external ||= false

    self
  end

  def canonical?
    parent_profile_id.blank?
  end

  def destroy_orphaned_business_objective
    return unless previous_changes.include?(:business_objective_id) &&
                  previous_changes[:business_objective_id].first.present?

    business_objective = BusinessObjective.find(
      previous_changes[:business_objective_id].first
    )
    business_objective.destroy if business_objective.profiles.empty?
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
    new_profile.add_rules(ref_ids: rules.select(:ref_id))
    new_profile
  end

  def in_account(account)
    Profile.find_by(account: account, ref_id: ref_id,
                    benchmark_id: benchmark_id)
  end

  def add_rules(ids: nil, ref_ids: nil)
    ProfileRule.import!(rule_ids_to_add(ids, ref_ids).map do |rule|
      ProfileRule.new(profile_id: id, rule_id: rule.id)
    end, ignore: true)
  end

  def major_os_version
    benchmark ? benchmark.inferred_os_major_version : 'N/A'
  end

  private

  def rule_ids_to_add(ids, ref_ids)
    benchmark.rules.select(:id).tap do |rel|
      return rel.where(id: ids) if ids
      return rel.where(ref_id: ref_ids) if ref_ids

      rel.where(id: parent_profile_rule_ids)
    end
  end

  def parent_profile_rule_ids
    return [] if parent_profile_id.blank?

    ProfileRule.select(:rule_id).where(profile_id: parent_profile_id)
  end
end
