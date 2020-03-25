# frozen_string_literal: true

# OpenSCAP profile
class Profile < ApplicationRecord
  include ProfileTailoring

  attribute :delete_all_test_results, :boolean, default: false

  scoped_search on: %i[id name ref_id account_id compliance_threshold]
  scoped_search relation: :hosts, on: :id, rename: :system_ids
  scoped_search relation: :hosts, on: :name, rename: :system_names

  has_many :profile_rules, dependent: :delete_all
  has_many :rules, through: :profile_rules, source: :rule
  has_many :profile_hosts, dependent: :delete_all
  has_many :hosts, through: :profile_hosts, source: :host
  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :test_results
  # rubocop:enable Rails/HasManyOrHasOneDependent
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
  before_destroy :destroy_all_test_results, if: -> { delete_all_test_results }

  scope :canonical, -> { where(parent_profile_id: nil) }

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

  def destroy_all_test_results
    DeleteTestResultsJob.perform_async(id)
  end

  def compliance_score(host)
    return 1 if results(host).count.zero?

    (results(host).count { |result| result == true }) / results(host).count
  end

  def compliant?(host)
    score(host: host) >= compliance_threshold
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

  def score(host: nil)
    results = test_results.latest
    results = results.where(host: host) if host
    return 0 if results.blank?

    (scores = results.pluck(:score)).sum / scores.size
  end

  def clone_to(account: nil, host: nil)
    new_profile = in_account(account)
    if new_profile.nil?
      (new_profile = dup).update!(account: account, hosts: [host],
                                  parent_profile: self)
    else
      new_profile.hosts << host unless new_profile.hosts.include?(host)
    end
    new_profile.add_rule_ref_ids(rules.pluck(:ref_id))
    new_profile
  end

  def in_account(account)
    Profile.find_by(account: account, ref_id: ref_id,
                    benchmark_id: benchmark_id)
  end

  def add_rule_ref_ids(ref_ids)
    rules = benchmark.rules.where(ref_id: ref_ids)
    ProfileRule.import!(rules.map do |rule|
      ProfileRule.new(profile_id: id, rule_id: rule.id)
    end, ignore: true)
  end

  def major_os_version
    benchmark ? benchmark.inferred_os_major_version : 'N/A'
  end
end
