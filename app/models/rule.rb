# frozen_string_literal: true

# Stores information about rules, such as which profiles can it be
# found in, what hosts are associated with it, etceter
class Rule < ApplicationRecord
  SORTED_SEVERITIES = Arel.sql(
    <<-SQL
    CASE WHEN severity = 'high' THEN 3
         WHEN severity = 'medium' THEN 2
         WHEN severity = 'low' THEN 1
         ELSE 0
    END
    SQL
  )

  sortable_by :title, :title
  sortable_by :severity, SORTED_SEVERITIES
  sortable_by :remediation_available, :remediation_available

  extend FriendlyId
  friendly_id :ref_id, use: :slugged
  scoped_search on: %i[id ref_id severity]
  scoped_search relation: :rule_references, on: :label, aliases: %i[reference]
  scoped_search relation: :rule_identifier, on: :label, aliases: %i[identifier]
  include OpenscapParserDerived
  include RuleRemediation

  has_many :profile_rules, dependent: :delete_all
  has_many :profiles, through: :profile_rules, source: :profile
  has_many :rule_results, dependent: :delete_all
  has_many :hosts, through: :rule_results, source: :host
  has_many :rule_references_rules, dependent: :delete_all
  has_many :rule_references, through: :rule_references_rules
  alias references rule_references
  has_one :rule_identifier, dependent: :destroy
  alias identifier rule_identifier
  belongs_to :benchmark, class_name: 'Xccdf::Benchmark'

  validates :title, presence: true
  validates :ref_id, uniqueness: { scope: %i[benchmark_id] }, presence: true
  validates :description, presence: true
  validates :severity, presence: true
  validates :benchmark_id, presence: true
  validates_associated :profile_rules
  validates_associated :rule_results

  scope :with_references, lambda { |reference_labels|
    joins(:rule_references).where(rule_references: { label: reference_labels })
  }

  scope :with_identifier, lambda { |identifier_label|
    joins(:rule_identifier).where(rule_identifiers: { label: identifier_label })
  }

  scope :with_profiles, lambda {
    joins(:profile_rules).where.not(profile_rules: { profile_id: nil }).distinct
  }

  scope :latest, lambda {
    where(benchmark_id: ::Xccdf::Benchmark.latest.pluck(:id))
  }

  scope :canonical, lambda {
    includes(:profiles).where(profiles: { id: Profile.canonical })
  }

  def canonical?
    (profiles & Profile.canonical).any?
  end

  def self.from_openscap_parser(op_rule, benchmark_id: nil)
    rule = find_or_initialize_by(ref_id: op_rule.id,
                                 benchmark_id: benchmark_id)

    rule.op_source = op_rule

    rule.assign_attributes(title: op_rule.title,
                           description: op_rule.description,
                           rationale: op_rule.rationale,
                           severity: op_rule.severity)

    rule
  end

  def compliant?(host, profile)
    Rails.cache.fetch("#{id}/#{host.id}/compliant") do
      return false unless profile.present? && profile.rules.include?(self)

      latest_rule_result = latest_result(host, profile)
      return false if latest_rule_result.blank?

      %w[pass notapplicable notselected].include? latest_rule_result.result
    end
  end

  def latest_result(host, profile)
    test_result = TestResult.latest.find_by(profile_id: profile.id,
                                            host_id: host.id)
    return nil if test_result.blank?

    test_result.rule_results.find_by(rule_id: id)
  end
end
