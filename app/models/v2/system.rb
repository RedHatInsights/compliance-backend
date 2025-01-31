# frozen_string_literal: true

module V2
  # Class representing read-only systems syndicated from the host-based inventory
  # rubocop:disable Metrics/ClassLength
  class System < ApplicationRecord
    self.table_name = 'inventory.hosts'
    self.primary_key = 'id'
    self.ignored_columns += %w[account]

    # FIXME: after the full remodel and V1 cleanup, inverse_of can be specified
    belongs_to :account, class_name: 'Account', primary_key: :org_id, foreign_key: :org_id # rubocop:disable Rails/InverseOf

    has_many :policy_systems, class_name: 'V2::PolicySystem', dependent: nil
    has_many :report_systems, class_name: 'V2::ReportSystem', dependent: nil
    has_many :policies, class_name: 'V2::Policy', through: :policy_systems
    has_many :reports, class_name: 'V2::Report', through: :report_systems
    has_many :test_results, class_name: 'V2::TestResult', dependent: :destroy, inverse_of: :system
    has_many :rule_results, class_name: 'V2::RuleResult', through: :test_results

    OWNER_ID = AN::InfixOperation.new('->>', arel_table[:system_profile], AN::Quoted.new('owner_id'))

    def self.os_version(table = arel_table)
      AN::InfixOperation.new('->', table[:system_profile], AN::Quoted.new('operating_system'))
    end

    def self.os_major_version(table = arel_table)
      AN::InfixOperation.new('->', os_version(table), AN::Quoted.new('major')).as('os_major_version')
    end

    def self.os_minor_version(table = arel_table)
      AN::InfixOperation.new('->', os_version(table), AN::Quoted.new('minor')).as('os_minor_version')
    end

    def self.last_check_in(table = arel_table)
      table[:per_reporter_staleness].as('last_check_in')
    end

    def self.sortable_os(table = arel_table)
      AN::NamedFunction.new(
        'ROW',
        [
          AN::NamedFunction.new('CAST', [V2::System.os_major_version(table).left.as('int')]),
          AN::NamedFunction.new('CAST', [V2::System.os_minor_version(table).left.as('int')])
        ]
      )
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
    sortable_by :os_major_version
    sortable_by :os_minor_version
    sortable_by :os_version, sortable_os
    sortable_by :groups, first_group_name

    searchable_by :display_name, %i[eq neq like unlike]

    searchable_by :os_version, %i[in], except_parents: %i[policies reports] do |_key, _op, val|
      jsons = val.split(',').each_with_object([]) do |version, obj|
        major, minor = version.split('.')

        obj << { operating_system: { major: major.to_i, minor: minor.to_i } }.to_json.dump
      end

      { conditions: arel_json_lookup(arel_table[:system_profile], jsons).to_sql }
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
      assigned = V2::PolicySystem.select(:system_id)
      scanned = V2::TestResult.select(:system_id)

      { conditions: "inventory.hosts.id IN (#{assigned.to_sql}) OR inventory.hosts.id IN (#{scanned.to_sql})" }
    end

    searchable_by :never_reported, %i[eq], only_parents: %i[reports] do |_key, _op, _val|
      ids = V2::TestResult.unscoped.select(:system_id, :report_id)

      { conditions: "(inventory.hosts.id, reports.id) NOT IN (#{ids.to_sql})" }
    end

    searchable_by :group_name, %i[eq in] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      systems = ::V2::System.unscoped.with_groups(values, :name)
      { conditions: systems.arel.where_sql.gsub(/^where /i, '') }
    end

    searchable_by :policies, %i[eq in], except_parents: %i[policies reports] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      ids = ::V2::PolicySystem.unscoped.where(policy_id: values).select(:system_id)

      { conditions: "inventory.hosts.id IN (#{ids.to_sql})" }
    end

    searchable_by :profile_ref_id, %i[neq notin], except_parents: %i[policies reports] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      ids = ::V2::PolicySystem.unscoped.joins(policy: :profile).where(profile: { ref_id: values }).select(:system_id)

      { conditions: "inventory.hosts.id NOT IN (#{ids.to_sql})" }
    end

    scope :with_groups, lambda { |groups, key = :id|
      # Skip the [] representing ungrouped hosts from the array when generating the query
      grouped = arel_json_lookup(arel_table[:groups], groups_as_json(groups.flatten, key))
      ungrouped = arel_table[:groups].eq(AN::Quoted.new('[]'))
      # The OR is inside of Arel in order to prevent pollution of already applied scopes
      where(groups.include?([]) ? grouped.or(ungrouped) : grouped)
    }

    scope :os_major_versions, lambda { |version, q = true|
      where(AN::NamedFunction.new('CAST', [os_major_version.left.as('int')]).send(q ? :in : :not_in, version))
    }

    scope :os_minor_versions, lambda { |version, q = true|
      where(AN::NamedFunction.new('CAST', [os_minor_version.left.as('int')]).send(q ? :in : :not_in, version))
    }

    def self.taggable?
      true
    end

    def readonly?
      Rails.env.production?
    end

    def group_ids
      groups.map { |group| group['id'] } || []
    end

    def os_major_version
      attributes['os_major_version'] || try(:system_profile)&.dig('operating_system', 'major')
    end

    def os_minor_version
      attributes['os_minor_version'] || try(:system_profile)&.dig('operating_system', 'minor')
    end

    def self.groups_as_json(groups, key = :id)
      groups.map { |group| [{ key => group }].to_json.dump }
    end
  end
  # rubocop:enable Metrics/ClassLength
end
