# frozen_string_literal: true

module V2
  # Class representing individual rule results unter a test result
  # rubocop:disable Metrics/ClassLength
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

    # Eliminates redundant joins to v2_test_results table
    scope :with_serializer_data, lambda {
      joins(build_rule_join)
        .joins(test_result: [:system, { tailoring: { profile: :security_guide } }])
        .select(*serializer_select_fields)
    }

    def self.serializer_dependencies
      @serializer_dependencies ||= begin
        deps = V2::RuleResultSerializer.dependencies([], %i[rule system profile security_guide])
        deps.transform_values(&:uniq) # remove duplicates
      end
    end

    class << self
      def serializer_select_fields
        [arel_table[Arel.star]] + association_fields
      end

      def build_rule_join
        rule_join = arel_table
                    .join(V2::Rule.arel_table.alias('rule'), Arel::Nodes::InnerJoin)
                    .on(V2::Rule.arel_table.alias('rule')[:id].eq(arel_table[:rule_id]))
        rule_join.join_sources
      end

      private

      def association_fields
        serializer_dependencies.flat_map do |association, fields|
          next [] if association.nil? # skip base model fields

          table = arel_table_for_association(association)
          fields.map { |field| table[field].as("#{association}__#{field}") }
        end
      end

      def arel_table_for_association(association)
        case association
        when :rule
          V2::Rule.arel_table.alias('rule')
        when :system
          Arel::Table.new(:hosts, as: 'system')
        when :profile
          V2::Profile.arel_table
        when :security_guide
          V2::SecurityGuide.arel_table
        end
      end
    end

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

    searchable_by :remediation_available, %i[eq], except_parents: %i[reports] do |_key, _op, val|
      {
        conditions: 'rule.remediation_available = ?',
        parameter: [ActiveModel::Type::Boolean.new.cast(val)]
      }
    end

    searchable_by :rule_group_id, %i[eq] do |_key, _op, val|
      {
        conditions: 'rule.rule_group_id = ?',
        parameter: [val]
      }
    end

    searchable_by :identifier_label, %i[eq neq like unlike] do |_key, op, val|
      val = "%#{val}%" if ['ILIKE', 'NOT ILIKE'].include?(op)

      {
        conditions: "rule.identifier->>'label' #{op} ?",
        parameter: [val]
      }
    end

    def ref_id
      attributes['rule__ref_id'] || try(:rule)&.ref_id
    end

    def rule_group_id
      attributes['rule__rule_group_id'] || try(:rule)&.rule_group_id
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

      sg_ref = security_guide__ref_id
      sg_ver = security_guide__version
      profile_ref = V2::Rule.short_ref_id(profile__ref_id)

      "ssg:#{sg_ref}|#{sg_ver}|#{profile_ref}|#{rule__ref_id}"
    rescue NameError
      raise ArgumentError, 'Missing security guide or profile on the ActiveRecord result'
    end
    # :nocov:
  end
  # rubocop:enable Metrics/ClassLength
end
