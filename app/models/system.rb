# frozen_string_literal: true

# Class representing systems
# rubocop:disable Metrics/ClassLength
class System < ApplicationRecord
  self.table_name = 'systems'
  self.primary_key = 'id'

  default_scope { where(deleted_at: nil) }

  belongs_to :account, class_name: 'Account', primary_key: :org_id, foreign_key: :org_id, inverse_of: :systems

  has_many :policy_systems, class_name: 'PolicySystem', dependent: nil
  has_many :report_systems, class_name: 'ReportSystem', dependent: nil
  has_many :policies, class_name: 'Policy', through: :policy_systems
  has_many :reports, class_name: 'Report', through: :report_systems
  has_many :test_results, class_name: 'TestResult', dependent: :destroy, inverse_of: :system
  has_many :rule_results, class_name: 'RuleResult', through: :test_results

  def self.os_major_version(table = arel_table)
    table[:os_major_version].as('os_major_version')
  end

  def self.os_minor_version(table = arel_table)
    table[:os_minor_version].as('os_minor_version')
  end

  def self.sortable_os(table = arel_table)
    AN::NamedFunction.new('ROW', [table[:os_major_version], table[:os_minor_version]])
  end

  OS_VERSION = AN::NamedFunction.new(
    'CONCAT', [os_major_version.left, AN::Quoted.new('.'), os_minor_version.left]
  ).as('os_version')

  def self.os_versions
    distinct.reorder(os_major_version.left, os_minor_version.left)
            .reselect(OS_VERSION, os_major_version, os_minor_version)
            .map(&:os_version)
  end

  # rubocop:disable Metrics/MethodLength
  def self.first_group_name(table = arel_table)
    AN::NamedFunction.new(
      'COALESCE', [
        AN::NamedFunction.new(
          'CAST',
          [
            AN::InfixOperation.new(
              '->>',
              AN::InfixOperation.new('->', table[:groups], 0),
              AN::Quoted.new('name')
            ).as('TEXT')
          ]
        ), AN::Quoted.new('')
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength

  POLICIES = AN::NamedFunction.new(
    'COALESCE', [
      AN::NamedFunction.new(
        'JSON_AGG', [
          AN::NamedFunction.new(
            'JSON_BUILD_OBJECT', [
              AN::Quoted.new('id'), Policy.arel_table[:id], AN::Quoted.new('title'), Policy.arel_table[:title]
            ]
          )
        ]
      ).filter(Policy.arel_table[:id].not_eq(nil)),
      AN::Quoted.new('[]')
    ]
  )

  sortable_by :display_name
  sortable_by :os_major_version, os_major_version.left
  sortable_by :os_minor_version, os_minor_version.left
  sortable_by :os_version, sortable_os
  sortable_by :groups, first_group_name

  searchable_by :display_name, %i[eq neq like unlike]

  searchable_by :os_version, %i[in], except_parents: %i[policies reports] do |_key, _op, val|
    conditions = val.split(',').filter_map do |version|
      major, minor = version.split('.', 2)
      next unless major&.match?(/\A\d+\z/) && minor&.match?(/\A\d+\z/)

      arel_table[:os_major_version].eq(major.to_i)
                                   .and(arel_table[:os_minor_version].eq(minor.to_i))
    end
    conditions = conditions.reduce(:or)

    { conditions: conditions ? conditions.to_sql : '1=0' }
  end

  searchable_by :os_major_version, %i[eq neq in notin], except_parents: %i[policies reports] do |_key, op, val|
    {
      conditions: unscoped.os_major_versions(val.split(',').map(&:to_i), %w[IN =].include?(op))
                          .arel.where_sql.sub(/^where /i, '')
    }
  end

  searchable_by :os_minor_version, %i[eq neq in notin] do |_key, op, val|
    {
      conditions: unscoped.os_minor_versions(val.split(',').map(&:to_i), %w[IN =].include?(op)).arel
                          .where_sql.sub(/^where /i, '')
    }
  end

  searchable_by :assigned_or_scanned, %i[eq], except_parents: %i[policies reports] do |_key, _op, _val|
    assigned = PolicySystem.select(:system_id)
    scanned = TestResult.select(:system_id)

    { conditions: "systems.id IN (#{assigned.to_sql}) OR systems.id IN (#{scanned.to_sql})" }
  end

  searchable_by :never_reported, %i[eq], only_parents: %i[reports] do |_key, _op, _val|
    ids = TestResult.unscoped.select(:system_id, :report_id)

    { conditions: "(systems.id, reports.id) NOT IN (#{ids.to_sql})" }
  end

  [%i[group_name name], %i[group_id id]].each do |field, key|
    searchable_by field, %i[eq in] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      systems = ::System.unscoped.with_groups(values, key)
      { conditions: systems.arel.where_sql.gsub(/^where /i, '') }
    end
  end

  searchable_by :policies, %i[eq in], except_parents: %i[policies reports] do |_key, _op, val|
    values = val.split(',').map(&:strip)
    ids = ::PolicySystem.unscoped.where(policy_id: values).select(:system_id)

    { conditions: "systems.id IN (#{ids.to_sql})" }
  end

  searchable_by :profile_ref_id, %i[neq notin], except_parents: %i[policies reports] do |_key, _op, val|
    values = val.split(',').map(&:strip)
    ids = ::PolicySystem.unscoped.joins(policy: :profile).where(profile: { ref_id: values }).select(:system_id)

    { conditions: "systems.id NOT IN (#{ids.to_sql})" }
  end

  searchable_by :available_for_policy_id, %i[eq], except_parents: %i[policies reports] do |_key, _op, val|
    { conditions: without_twin_policy(val) }
  rescue ActiveRecord::RecordNotFound
    { conditions: 'FALSE' }
  end

  scope :with_groups, lambda { |groups, key = :id|
    # Skip the [] representing ungrouped hosts from the array when generating the query
    grouped = arel_json_lookup(arel_table[:groups], groups_as_json(groups.flatten, key))
    ungrouped = arel_table[:groups].eq(AN::Quoted.new('[]'))
    # The OR is inside of Arel in order to prevent pollution of already applied scopes
    where(groups.include?([]) ? grouped.or(ungrouped) : grouped)
  }

  scope :os_major_versions, lambda { |version, q = true|
    where(arel_table[:os_major_version].send(q ? :in : :not_in, version))
  }

  scope :os_minor_versions, lambda { |version, q = true|
    where(arel_table[:os_minor_version].send(q ? :in : :not_in, version))
  }

  def self.taggable?
    true
  end

  def stale_warning_timestamp
    stale_timestamp ? stale_timestamp + 7.days : nil
  end

  def culled_timestamp
    stale_timestamp ? stale_timestamp + 14.days : nil
  end

  def last_check_in
    stale_timestamp ? stale_timestamp + 8.days : nil
  end

  def group_ids
    groups.map { |group| group['id'] } || []
  end

  def self.groups_as_json(groups, key = :id)
    groups.map { |group| [{ key => group }].to_json.dump }
  end

  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def self.without_twin_policy(policy_id)
    target_policy = Policy.joins(profile: :security_guide)
                          .where(account_id: User.current.account_id)
                          .select('policies.id AS policy_id',
                                  'profiles.ref_id AS cp_ref_id',
                                  'security_guides.os_major_version AS sg_os_major_version')
                          .find(policy_id)

    excluded = PolicySystem.joins(policy: { profile: :security_guide })
                           .where(
                             Profile.arel_table[:ref_id].eq(target_policy.cp_ref_id)
                             .and(
                               SecurityGuide.arel_table[:os_major_version]
                                            .eq(target_policy.sg_os_major_version)
                             )
                             .and(Policy.arel_table[:id].not_eq(target_policy.policy_id))
                           )
                           .where(PolicySystem.arel_table[:system_id].eq(arel_table[:id]))
                           .arel
                           .exists

    assigned = arel_table[:id].in(PolicySystem.where(policy_id: policy_id).select(:system_id))

    Arel::Nodes::Not.new(excluded).or(assigned).to_sql
  end
  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
end
# rubocop:enable Metrics/ClassLength
