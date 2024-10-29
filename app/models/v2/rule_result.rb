# frozen_string_literal: true

module V2
  # Class representing individual rule results unter a test result
  class RuleResult < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :rule_results
    self.ignored_columns += %w[account host_id]

    belongs_to :test_result, class_name: 'V2::TestResult'
    belongs_to :historical_test_result, class_name: 'V2::HistoricalTestResult', foreign_key: :test_result_id,
                                        inverse_of: :rule_results, optional: true
    belongs_to :rule, class_name: 'V2::Rule'

    has_one :system, class_name: 'V2::System', through: :test_result
    has_one :tailoring, class_name: 'V2::Tailoring', through: :test_result
    has_one :report, class_name: 'V2::Report', through: :test_result
    has_one :profile, class_name: 'V2::Profile', through: :tailoring
    has_one :security_guide, class_name: 'V2::SecurityGuide', through: :profile
    has_one :account, class_name: 'V2::Account', through: :report

    NOT_SELECTED = %w[notapplicable notchecked informational notselected].freeze
    PASSED = %w[pass].freeze
    FAILED = %w[fail error unknown fixed].freeze
    SELECTED = (PASSED + FAILED).freeze

    scope :passed, -> { where(result: PASSED) }
    scope :failed, -> { where(result: FAILED) }

    scope :with_groups, lambda { |groups, table = V2::System.arel_table|
      # Skip the [] representing ungrouped hosts from the array when generating the query
      grouped = arel_json_lookup(table[:groups], V2::System.groups_as_json(groups.flatten, :id))
      ungrouped = table[:groups].eq(AN::Quoted.new('[]'))
      # The OR is inside of Arel in order to prevent pollution of already applied scopes
      where(groups.include?([]) ? grouped.or(ungrouped) : grouped)
    }

    sortable_by :result
    sortable_by :severity, V2::Rule.sorted_severities(V2::Rule.arel_table.alias('rule'))
    sortable_by :title, V2::Rule.arel_table.alias('rule')[:title]
    sortable_by :precedence, V2::Rule.arel_table.alias('rule')[:precedence]
    sortable_by :remediation_available, V2::Rule.arel_table.alias('rule')[:remediation_available]

    searchable_by :result, %i[eq ne in notin]

    searchable_by :title, %i[eq neq like unlike] do |_key, op, val|
      val = "%#{val}%" if ['ILIKE', 'NOT ILIKE'].include?(op)
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "rule.title #{op} #{bind}",
        parameter: [val]
      }
    end

    searchable_by :severity, %i[eq ne in notin] do |_key, op, val|
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "rule.severity #{op} #{bind}",
        parameter: [val.split(',')]
      }
    end

    searchable_by :remediation_available, %i[eq] do |_key, _op, val|
      {
        conditions: 'rule.remediation_available = ?',
        parameter: [ActiveModel::Type::Boolean.new.cast(val)]
      }
    end

    def ref_id
      attributes['rule__ref_id'] || try(:rule)&.ref_id
    end

    def title
      attributes['rule__title'] || try(:rule)&.title
    end

    def rationale
      attributes['rule__rationale'] || try(:rule)&.rationale
    end

    def description
      attributes['rule__description'] || try(:rule)&.description
    end

    def severity
      attributes['rule__severity'] || try(:rule)&.severity
    end

    def precedence
      attributes['rule__precedence'] || try(:rule)&.precedence
    end

    def identifier
      attributes['rule__identifier'] || try(:rule)&.identifier
    end

    def references
      attributes['rule__references'] || try(:rule)&.references
    end

    def value_checks
      attributes['rule__value_checks'] || try(:rule)&.value_checks
    end

    def system_id
      attributes['system__id'] || try(:system)&.id
    end

    # FIXME: refactor the method under V2::Rule and have it just in one place
    # :nocov:
    def remediation_issue_id
      return nil unless attributes['rule__remediation_available']

      sg_ref = V2::Rule.short_ref_id(security_guide__ref_id).sub('-', '')
      profile_ref = V2::Rule.short_ref_id(profile__ref_id)

      "ssg:#{sg_ref}|#{profile_ref}|#{rule__ref_id}"
    rescue NameError
      raise ArgumentError, 'Missing security guide or profile on the ActiveRecord result'
    end
    # :nocov:
  end
end
