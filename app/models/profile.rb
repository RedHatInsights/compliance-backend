# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  scoped_search on: %i[id name ref_id account_id compliance_threshold]

  has_many :profile_rules, dependent: :delete_all
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :delete_all
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

  scope :canonical, -> { where(account_id: nil) }

  def self.from_openscap_parser(op_profile, benchmark_id: nil, account_id: nil)
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

  def canonical?
    account_id.blank?
  end

  def destroy_orphaned_business_objective
    return unless previous_changes.include?(:business_objective_id) &&
                  previous_changes[:business_objective_id].first.present?

    business_objective = BusinessObjective.find(
      previous_changes[:business_objective_id].first
    )
    business_objective.destroy if business_objective.profiles.empty?
  end

  def compliance_score(host)
    return 1 if results(host).count.zero?

    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    host_results = results(host)
    host_results.present? &&
      (host_results.count(true) / host_results.count.to_f) >=
        (compliance_threshold / 100.0)
  end

  def rules_for_system(host, selected_columns = [:id])
    host.selected_rules(self, selected_columns)
  end

  # Disabling MethodLength because it measures things wrong
  # for a multi-line string SQL query.
  def results(host)
    Rails.cache.fetch("#{id}/#{host.id}/results", expires_in: 1.week) do
      rule_results = TestResult.where(profile: self, host: host)
                               .order('created_at DESC')&.first&.rule_results
      return [] if rule_results.blank?

      rule_results.map do |rule_result|
        %w[pass notapplicable notselected].include? rule_result.result
      end
    end
  end

  def score
    return 1 if hosts.blank?

    (hosts.count { |host| compliant?(host) }).to_f / hosts.count
  end

  def clone_to(account: nil, host: nil)
    new_profile = in_account(account)
    if new_profile.nil?
      (new_profile = dup).update!(account: account, hosts: [host])
    else
      new_profile.hosts << host unless new_profile.hosts.include?(host)
    end
    new_profile.add_rules_from(profile: self)
    new_profile
  end

  def in_account(account)
    Profile.find_by(account: account, ref_id: ref_id,
                    benchmark_id: benchmark_id)
  end

  def add_rules_from(profile: nil)
    new_profile_rules = profile.profile_rules - profile_rules
    ProfileRule.import!(new_profile_rules.map do |profile_rule|
      new_profile_rule = profile_rule.dup
      new_profile_rule.profile = self
      new_profile_rule
    end, ignore: true)
  end

  def major_os_version
    benchmark ? benchmark.inferred_os_major_version : 'N/A'
  end
end
