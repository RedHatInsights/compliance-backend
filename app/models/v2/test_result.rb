# frozen_string_literal: true

module V2
  # Database model representing latest results of compliance scans
  class TestResult < ApplicationRecord
    # FIXME: clean up after the remodel
    self.table_name = :v2_test_results
    self.primary_key = :id

    if Rails.env.test? # For testing taggable
      belongs_to :system, class_name: 'V2::System', optional: true, autosave: true
      delegate :tags=, to: :system
    else
      belongs_to :system, class_name: 'V2::System', optional: true
    end

    belongs_to :tailoring, class_name: 'V2::Tailoring'
    belongs_to :report, class_name: 'V2::Report', optional: true

    has_one :profile, class_name: 'V2::Profile', through: :tailoring
    has_one :security_guide, class_name: 'V2::SecurityGuide', through: :profile
    has_one :policy, class_name: 'V2::Policy', through: :tailoring
    has_one :account, class_name: 'V2::Account', through: :policy

    has_many :rule_results, class_name: 'V2::RuleResult', dependent: :destroy

    sortable_by :display_name, V2::System.arel_table.alias('system')[:display_name]
    sortable_by :security_guide_version, V2::SecurityGuide.arel_table.alias('security_guide')[:version]
    sortable_by :groups, V2::System.first_group_name(V2::System.arel_table.alias('system'))
    sortable_by :score
    sortable_by :end_time
    sortable_by :failed_rule_count

    searchable_by :score, %i[eq gt lt gte lte]
    searchable_by :supported, %i[eq]
    searchable_by :system_id, %i[eq]

    searchable_by :display_name, %i[eq ne like unlike] do |_key, op, val|
      val = "%#{val}%" if ['ILIKE', 'NOT ILIKE'].include?(op)

      {
        conditions: "system.display_name #{op} ?",
        parameter: [val]
      }
    end

    searchable_by :os_minor_version, %i[eq ne in notin] do |_key, op, val|
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "CAST(system.system_profile->'operating_system'->>'minor' AS int) #{op} #{bind}",
        parameter: [val.split(',').map(&:to_i)]
      }
    end

    searchable_by :security_guide_version, %i[eq ne in notin] do |_key, op, val|
      bind = ['IN', 'NOT IN'].include?(op) ? '(?)' : '?'

      {
        conditions: "security_guide.version #{op} #{bind}",
        parameter: [val.split(',')]
      }
    end

    searchable_by :compliant, %i[eq] do |_key, _op, val|
      op = ActiveModel::Type::Boolean.new.cast(val) ? '>=' : '<'

      {
        conditions: "score #{op} report.compliance_threshold AND supported = true"
      }
    end

    searchable_by :group_name, %i[eq in] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      systems = ::V2::TestResult.unscoped.with_groups(values, V2::System.arel_table.alias(:system), :name)
      { conditions: systems.arel.where_sql.gsub(/^where /i, '') }
    end

    searchable_by :failed_rule_severity, %i[eq in] do |_key, _op, val|
      ids = ::V2::RuleResult.unscoped.joins(:rule)
                            .where(rules_v2: { severity: val.split(',') }, rule_results: { result: 'fail' })
                            .select(:test_result_id)

      { conditions: "v2_test_results.id IN (#{ids.to_sql})" }
    end

    scope :with_groups, lambda { |groups, table = V2::System.arel_table, key = :id|
      # Skip the [] representing ungrouped hosts from the array when generating the query
      grouped = arel_json_lookup(table[:groups], V2::System.groups_as_json(groups.flatten, key))
      ungrouped = table[:groups].eq(AN::Quoted.new('[]'))
      # The OR is inside of Arel in order to prevent pollution of already applied scopes
      where(groups.include?([]) ? grouped.or(ungrouped) : grouped)
    }

    def self.taggable?
      true
    end

    def display_name
      attributes['system__display_name'] || try(:system)&.display_name
    end

    def groups
      attributes['system__groups'] || try(:system)&.groups
    end

    def tags
      attributes['system__tags'] || try(:system)&.tags
    end

    def os_major_version
      cached = attributes['system__system_profile']&.dig('operating_system', 'major')
      cached || try(:system).try(:system_profile)&.dig('operating_system', 'major')
    end

    def os_minor_version
      cached = attributes['system__system_profile']&.dig('operating_system', 'minor')
      cached || try(:system).try(:system_profile)&.dig('operating_system', 'minor')
    end

    def compliant
      threshold = attributes['report__compliance_threshold'] || try(:report)&.compliance_threshold
      !score.nil? && score >= threshold.to_f
    end

    def security_guide_version
      attributes['security_guide__version'] || try(:security_guide)&.version
    end

    def self.os_versions
      aliased_table = V2::System.arel_table.alias('system')
      major = V2::System.os_major_version(aliased_table)
      minor = V2::System.os_minor_version(aliased_table)
      concat = AN::NamedFunction.new('CONCAT', [major.left, AN::Quoted.new('.'), minor.left]).as('os_version')

      distinct.reorder(major.left, minor.left).reselect(concat, major, minor).map(&:os_version)
    end

    def self.security_guide_versions
      reselect(security_guide: [:version])
        .reorder(version_to_array(V2::SecurityGuide.arel_table.alias('security_guide')[:version]))
        .map(&:version)
        .uniq # using this instead of `.distinct` to properly handle sorting of versions. It should still perform fine.
    end
  end
end
