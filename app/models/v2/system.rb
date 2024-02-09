# frozen_string_literal: true

module V2
  # Class representing read-only systems syndicated from the host-based inventory
  class System < ApplicationRecord
    self.table_name = 'inventory.hosts'
    self.primary_key = 'id'

    # rubocop:disable Rails/InverseOf
    # FIXME: after the full remodel and V1 cleanup, inverse_of can be specified
    belongs_to :account, class_name: 'Account', primary_key: :org_id, foreign_key: :org_id
    # rubocop:enable Rails/InverseOf
    has_many :policy_systems, class_name: 'V2::PolicySystem', foreign_key: :host_id, inverse_of: :system, dependent: nil
    has_many :policies, through: :policy_systems

    OS_VERSION = AN::InfixOperation.new(
      '->',
      Host.arel_table[:system_profile],
      AN::Quoted.new('operating_system')
    )

    OS_MINOR_VERSION = AN::InfixOperation.new(
      '->',
      OS_VERSION,
      AN::Quoted.new('minor')
    ).as('os_minor_version')

    OS_MAJOR_VERSION = AN::InfixOperation.new(
      '->',
      OS_VERSION,
      AN::Quoted.new('major')
    ).as('os_major_version')

    FIRST_GROUP_NAME = AN::NamedFunction.new(
      'COALESCE', [
        AN::NamedFunction.new(
          'CAST',
          [
            AN::InfixOperation.new(
              '->>',
              AN::InfixOperation.new('->', arel_table[:groups], 0),
              AN::Quoted.new('name')
            ).as('TEXT')
          ]
        ), AN::Quoted.new('')
      ]
    )

    sortable_by :display_name
    sortable_by :os_major_version
    sortable_by :os_minor_version
    sortable_by :groups, FIRST_GROUP_NAME

    searchable_by :display_name, %i[eq neq like unlike]
    searchable_by :os_major_version, %i[eq neq in notin] do |_key, op, val|
      query = ['IN', '='].include?(op) ? :in : :not_in

      {
        conditions: AN::NamedFunction.new(
          'CAST', [OS_MAJOR_VERSION.left.as('int')]
        ).send(query, val.split.map(&:to_i)).to_sql
      }
    end
    searchable_by :os_minor_version, %i[eq neq in notin] do |_key, op, val|
      query = ['IN', '='].include?(op) ? :in : :not_in

      {
        conditions: AN::NamedFunction.new(
          'CAST', [OS_MINOR_VERSION.left.as('int')]
        ).send(query, val.split.map(&:to_i)).to_sql
      }
    end

    scope :with_groups, lambda { |groups, key = :id|
      # Skip the [] representing ungrouped hosts from the array when generating the query
      grouped = arel_inventory_groups(groups.flatten, key)
      ungrouped = arel_table[:groups].eq(AN::Quoted.new('[]'))
      # The OR is inside of Arel in order to prevent pollution of already applied scopes
      where(groups.include?([]) ? grouped.or(ungrouped) : grouped)
    }

    # :nocov:
    def readonly?
      Rails.env.production?
    end
    # :nocov:

    def group_ids
      groups.map { |group| group['id'] } || []
    end

    def self.arel_inventory_groups(groups, key)
      jsons = groups.map { |group| [{ key => group }].to_json.dump }

      return AN::InfixOperation.new('=', Arel.sql('1'), Arel.sql('0')) if jsons.empty?

      AN::InfixOperation.new(
        '@>', arel_table[:groups],
        AN::NamedFunction.new(
          'ANY', [
            AN::NamedFunction.new('CAST', [AN.build_quoted("{#{jsons.join(',')}}").as('jsonb[]')])
          ]
        )
      )
    end
  end
end
