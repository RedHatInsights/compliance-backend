# frozen_string_literal: true

# Model for reports
class Report < ApplicationRecord
  # FIXME: clean up after the remodel
  self.table_name = :policies_v2
  self.primary_key = :id

  SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
      Pundit.policy_scope(User.current, System).where_clause.ast
    )
  end

  REPORTED_SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
      Pundit.policy_scope(User.current, System).where_clause.ast.and(
        TestResult.arel_table[:id].not_eq(nil)
      )
    )
  end

  COMPLIANT_SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
      Pundit.policy_scope(User.current, System).where_clause.ast
        .and(TestResult.arel_table[:score].gteq(Report.arel_table[:compliance_threshold]))
        .and(TestResult.arel_table[:supported].eq(true))
    )
  end

  UNSUPPORTED_SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
      Pundit.policy_scope(User.current, System).where_clause.ast.and(
        TestResult.arel_table[:supported].not_eq('t')
      )
    )
  end

  NEVER_REPORTED_SYSTEM_COUNT = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
      Pundit.policy_scope(User.current, System).where_clause.ast.and(
        TestResult.arel_table[:id].eq(nil)
      )
    )
  end

  ALL_SYSTEMS_EXPOSED = lambda do
    AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).eq(
      AN::NamedFunction.new('COUNT', [System.arel_table[:id]]).filter(
        Pundit.policy_scope(User.current, System).where_clause.ast
      )
    )
  end

  PERCENT_COMPLIANT = lambda do
    AN::NamedFunction.new(
      'COALESCE',
      [
        AN::Division.new(
          AN::Multiplication.new(COMPLIANT_SYSTEM_COUNT.call, Arel.sql('100')),
          AN::NamedFunction.new('NULLIF', [SYSTEM_COUNT.call, Arel.sql('0')])
        ),
        Arel.sql('0')
      ]
    )
  end

  # To prevent an autojoin with itself, there should not be an inverse relationship specified
  belongs_to :policy, class_name: 'Policy', foreign_key: :id # rubocop:disable Rails/InverseOf
  belongs_to :account

  belongs_to :profile, class_name: 'Profile'
  has_one :security_guide, through: :profile, class_name: 'SecurityGuide'
  has_many :tailorings, class_name: 'Tailoring', foreign_key: :policy_id, dependent: nil # rubocop:disable Rails/InverseOf
  has_many :test_results, class_name: 'TestResult', dependent: nil, through: :tailorings
  has_many :report_systems, class_name: 'ReportSystem', dependent: nil # rubocop:disable Rails/InverseOf
  has_many :systems, class_name: 'System', through: :report_systems
  has_many :reported_systems, class_name: 'System', through: :test_results, source: :system, dependent: nil
  has_many :reporting_and_non_reporting_systems, lambda {
    # joining TestResult and System to correctly count the system with content to report
    system_test_results = arel_table.join(System.arel_table, AN::InnerJoin)
                                    .on(System.arel_table[:id].eq(ReportSystem.arel_table[:system_id]))
                                    .join(TestResult.arel_table, AN::OuterJoin)
                                    .on(
                                      TestResult.arel_table[:system_id].eq(System.arel_table[:id])
                                      .and(TestResult.arel_table[:report_id]
                                      .eq(ReportSystem.arel_table[:report_id]))
                                    )
                                    .join_sources

    # aggregation to prevent optimizer (possibly buggy) filtering out join
    agg = TestResult.arel_table[:id]
                    .not_eq(nil)
                    .or(TestResult.arel_table[:id].eq(nil))

    joins(system_test_results).where(agg)
  }, class_name: 'ReportSystem', dependent: nil, inverse_of: false

  sortable_by :title
  sortable_by :os_major_version
  sortable_by :business_objective
  sortable_by :compliance_threshold
  sortable_by :percent_compliant, 'aggregate_percent_compliant'

  searchable_by :title, %i[like unlike eq ne]
  searchable_by :os_major_version, %i[eq ne in notin], except_parents: %i[systems] do |_key, op, val|
    bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

    {
      conditions: "security_guide.os_major_version #{op} #{bind}",
      parameter: [val.split(',').map(&:to_i)]
    }
  end
  searchable_by :with_reported_systems, %i[eq], except_parents: %i[systems] do |_key, _op, _val|
    ids = Report.unscoped.joins(:reported_systems)
                .merge_with_alias(Pundit.policy_scope(User.current, System))
                .select(:id)

    { conditions: "policies_v2.id IN (#{ids.to_sql})" }
  end
  searchable_by :percent_compliant, %i[eq gt lt gte lte], except_parents: %i[systems] do |_key, op, val|
    {
      conditions: "aggregate_percent_compliant #{op} ?",
      parameter: [val]
    }
  end

  validates :account, presence: true

  def os_major_version
    attributes['security_guide__os_major_version'] || try(:security_guide)&.os_major_version
  end

  def ref_id
    attributes['profile__ref_id'] || try(:profile)&.ref_id
  end

  def profile_title
    attributes['profile__title'] || try(:profile)&.title
  end

  def delete_associated
    tailoring_ids = Tailoring.where(policy_id: id).select(:id)

    RuleResult.joins(:historical_test_result)
              .where(historical_test_result: { tailoring_id: tailoring_ids })
              .delete_all

    HistoricalTestResult.where(tailoring_id: tailoring_ids).delete_all
  end

  # rubocop:disable Metrics/AbcSize
  def top_failed_rules
    rule_fields = %i[title ref_id identifier severity].map { |field| Rule.arel_table[field] }

    RuleResult.joins(:system, :rule) # Because joins(test_results: :system, rule: []) is not that pretty
              .merge_with_alias(Pundit.policy_scope(User.current, System))
              .where(result: RuleResult::FAILED, v2_test_results: { report_id: id }) # FIXME: aliasing
              .group(rule_fields).select(rule_fields, RuleResult.arel_table[:result].count.as('count'))
              .order(Rule.sorted_severities => :desc, count: :desc).limit(10)
  end
  # rubocop:enable Metrics/AbcSize

  def self.os_versions
    reselect(security_guide: [:os_major_version]).distinct.reorder(:os_major_version).map do |row|
      row['os_major_version']
    end
  end
end
