# frozen_string_literal: true

module V2
  # Model for reports
  class Report < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_policies
    self.primary_key = :id

    def percent_compliant
      0
    end

    SYSTEM_COUNT = lambda do
      AN::NamedFunction.new('COUNT', [V2::System.arel_table[:id]]).filter(
        Pundit.policy_scope(User.current, V2::System).where_clause.ast
      )
    end

    COMPLIANT_SYSTEM_COUNT = lambda do
      AN::NamedFunction.new('COUNT', [V2::System.arel_table[:id]]).filter(
        Pundit.policy_scope(User.current, V2::System).where_clause.ast.and(
          V2::TestResult.arel_table[:score].gteq(V2::Report.arel_table[:compliance_threshold])
        )
      )
    end

    UNSUPPORTED_SYSTEM_COUNT = lambda do
      AN::NamedFunction.new('COUNT', [V2::System.arel_table[:id]]).filter(
        Pundit.policy_scope(User.current, V2::System).where_clause.ast.and(
          V2::TestResult.arel_table[:supported].not_eq('t')
        )
      )
    end

    # To prevent an autojoin with itself, there should not be an inverse relationship specified
    belongs_to :policy, class_name: 'V2::Policy', foreign_key: :id # rubocop:disable Rails/InverseOf
    belongs_to :account

    belongs_to :profile, class_name: 'V2::Profile'
    has_one :security_guide, through: :profile, class_name: 'V2::SecurityGuide'
    has_many :tailorings, class_name: 'V2::Tailoring', foreign_key: :policy_id, dependent: nil # rubocop:disable Rails/InverseOf
    has_many :test_results, class_name: 'V2::TestResult', dependent: nil, through: :tailorings
    has_many :report_systems, class_name: 'V2::ReportSystem', dependent: nil # rubocop:disable Rails/InverseOf
    has_many :systems, class_name: 'V2::System', through: :report_systems
    has_many :reported_systems, class_name: 'V2::System', through: :test_results, source: :system, dependent: nil

    sortable_by :title
    sortable_by :os_major_version
    sortable_by :business_objective
    sortable_by :compliance_threshold
    sortable_by :compliance_percentage, Arel.sql('0')

    searchable_by :title, %i[like unlike eq ne in notin]
    searchable_by :os_major_version, %i[eq ne in notin] do |_key, op, val|
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "security_guide.os_major_version #{op} #{bind}",
        parameter: [val.split.map(&:to_i)]
      }
    end
    searchable_by :with_reported_systems, %i[eq] do |_key, _op, _val|
      ids = V2::Report.joins(:test_results).reselect(:id)

      { conditions: "v2_policies.id IN (#{ids.to_sql})" }
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

    def all_systems_exposed
      total_system_count == try(:aggregate_assigned_system_count)
    end

    def delete_associated
      tailoring_ids = V2::Tailoring.where(policy_id: id).select(:id)

      V2::RuleResult.joins(:historical_test_result)
                    .where(historical_test_result: { tailoring_id: tailoring_ids })
                    .delete_all

      V2::HistoricalTestResult.where(tailoring_id: tailoring_ids).delete_all
    end

    # rubocop:disable Metrics/AbcSize
    def top_failed_rules
      V2::RuleResult.joins(:test_result, :system, :rule)
                    .merge_with_alias(Pundit.policy_scope(User.current, V2::System))
                    .where(result: V2::RuleResult::FAILED)
                    .group(V2::Rule.arel_table[:ref_id], V2::Rule.arel_table[:severity])
                    .select(V2::Rule.arel_table[:ref_id], V2::Rule.arel_table[:severity],
                            V2::RuleResult.arel_table[:result].count.as('count'))
                    .order(count: :desc).limit(10)
    end
    # rubocop:enable Metrics/AbcSize
  end
end
