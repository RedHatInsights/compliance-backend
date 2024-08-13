# frozen_string_literal: true

module V2
  # Class representing read-only systems syndicated from the host-based inventory
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

    OS_VERSIONS = AN::NamedFunction.new(
      'CONCAT', [os_major_version.left, AN::Quoted.new('.'), os_minor_version.left]
    ).as('os_version')

    def self.os_versions
      distinct.reorder(os_major_version.left, os_minor_version.left)
              .reselect(OS_VERSIONS, os_major_version, os_minor_version)
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
    sortable_by :groups, first_group_name

    searchable_by :display_name, %i[eq neq like unlike]

    searchable_by :os_major_version, %i[eq neq in notin] do |_key, op, val|
      {
        conditions: os_major_versions(val.split.map(&:to_i), %w[IN =].include?(op)).arel.where_sql.sub(/^where /i, '')
      }
    end

    searchable_by :os_minor_version, %i[eq neq in notin] do |_key, op, val|
      {
        conditions: os_minor_versions(val.split.map(&:to_i), %w[IN =].include?(op)).arel.where_sql.sub(/^where /i, '')
      }
    end

    searchable_by :assigned_or_scanned, %i[eq] do |_key, _op, _val|
      ids = V2::System.where(id: V2::PolicySystem.select(:system_id)).or(
        V2::System.where(id: V2::TestResult.select(:system_id))
      ).reselect(:id)

      { conditions: "inventory.hosts.id IN (#{ids.to_sql})" }
    end

    searchable_by :never_reported, %i[eq] do |_key, _op, _val|
      ids = V2::TestResult.reselect(:system_id, :report_id)

      { conditions: "(inventory.hosts.id, reports.id) NOT IN (#{ids.to_sql})" }
    end

    searchable_by :group_name, %i[eq in] do |_key, _op, val|
      values = val.split(',').map(&:strip)
      systems = ::V2::System.with_groups(values, :name)
      { conditions: systems.arel.where_sql.gsub(/^where /i, '') }
    end

    searchable_by :policies, %i[eq in] do |_key, _op, val|
      values = val.split.map(&:strip)
      ids = ::V2::PolicySystem.where(policy_id: values).select(:system_id)

      { conditions: "inventory.hosts.id IN (#{ids.to_sql})" }
    end

    scope :with_groups, lambda { |groups, key = :id|
      # Skip the [] representing ungrouped hosts from the array when generating the query
      grouped = arel_inventory_groups(groups.flatten, key, arel_table)
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

    def self.arel_inventory_groups(groups, key, table)
      jsons = groups.map { |group| [{ key => group }].to_json.dump }

      return AN::InfixOperation.new('=', Arel.sql('1'), Arel.sql('0')) if jsons.empty?

      AN::InfixOperation.new(
        '@>', table[:groups],
        AN::NamedFunction.new(
          'ANY', [
            AN::NamedFunction.new('CAST', [AN.build_quoted("{#{jsons.join(',')}}").as('jsonb[]')])
          ]
        )
      )
    end
  end
end
