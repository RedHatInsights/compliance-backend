# frozen_string_literal: true

# Database model representing latest results of compliance scans
# rubocop:disable Metrics/ClassLength
class TestResult < ApplicationRecord
  # FIXME: clean up after the remodel
  self.table_name = :v2_test_results
  self.primary_key = :id

  if Rails.env.test? # For testing taggable
    belongs_to :system, class_name: 'System', optional: true, autosave: true
    delegate :tags=, to: :system
  else
    belongs_to :system, class_name: 'System', optional: true
  end

  belongs_to :tailoring, class_name: 'Tailoring'
  belongs_to :report, class_name: 'Report', optional: true

  has_one :profile, class_name: 'Profile', through: :tailoring
  has_one :security_guide, class_name: 'SecurityGuide', through: :profile
  has_one :policy, class_name: 'Policy', through: :tailoring
  has_one :account, class_name: 'Account', through: :policy

  has_many :rule_results, class_name: 'RuleResult', dependent: :destroy

  sortable_by :display_name, System.arel_table.alias('system')[:display_name]
  sortable_by :security_guide_version, SecurityGuide.arel_table.alias('security_guide')[:version]
  sortable_by :groups, System.first_group_name(System.arel_table.alias('system'))
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

  [%i[group_name name], %i[group_id id]].each do |field, key|
    searchable_by field, %i[eq in] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      systems = ::TestResult.unscoped.with_groups(values, System.arel_table.alias(:system), key)
      { conditions: systems.arel.where_sql.gsub(/^where /i, '') }
    end
  end

  searchable_by :failed_rule_severity, %i[eq in] do |_key, _op, val|
    ids = ::RuleResult.unscoped.joins(:rule)
                      .where(rules_v2: { severity: val.split(',') }, rule_results_v2: { result: 'fail' })
                      .select(:test_result_id)

    { conditions: "v2_test_results.id IN (#{ids.to_sql})" }
  end

  scope :with_groups, lambda { |groups, table = System.arel_table, key = :id|
    # Skip the [] representing ungrouped hosts from the array when generating the query
    grouped = arel_json_lookup(table[:groups], System.groups_as_json(groups.flatten, key))
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

  def compliant # rubocop:disable Naming/PredicateMethod
    threshold = attributes['report__compliance_threshold'] || try(:report)&.compliance_threshold
    !score.nil? && score >= threshold.to_f
  end

  def security_guide_version
    attributes['security_guide__version'] || try(:security_guide)&.version
  end

  def self.os_versions
    aliased_table = System.arel_table.alias('system')
    major = System.os_major_version(aliased_table)
    minor = System.os_minor_version(aliased_table)
    concat = AN::NamedFunction.new('CONCAT', [major.left, AN::Quoted.new('.'), minor.left]).as('os_version')

    distinct.reorder(major.left, minor.left).reselect(concat, major, minor).map(&:os_version)
  end

  def self.security_guide_versions
    reselect(security_guide: [:version])
      .reorder(version_to_array(SecurityGuide.arel_table.alias('security_guide')[:version]))
      .map(&:version)
      .uniq # using this instead of `.distinct` to properly handle sorting of versions. It should still perform fine.
  end
end
# rubocop:enable Metrics/ClassLength
