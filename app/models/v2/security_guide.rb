# frozen_string_literal: true

module V2
  # Model for Security Guides
  class SecurityGuide < ApplicationRecord
    self.table_name = 'benchmarks'

    SORT_BY_VERSION = Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::NamedFunction.new(
          'string_to_array',
          [arel_table[:version], Arel::Nodes::Quoted.new('.')]
        ).as('int[]')
      ]
    )

    SORT_BY_OS_MAJOR_VERSION = Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::NamedFunction.new(
          'regexp_replace',
          [
            V2::SecurityGuide.arel_table[:ref_id],
            Arel::Nodes::Quoted.new('.+RHEL-(\\d+)$'),
            Arel::Nodes::Quoted.new('\\1')
          ]
        ).as('int')
      ]
    )

    has_many :profiles, class_name: 'V2::Profile', dependent: :destroy
    has_many :value_definitions, class_name: 'V2::ValueDefinitions', dependent: :destroy
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: %i[version ref_id], only_explicit: true, operators: %i[eq ne in notin]
    scoped_search on: :os_major_version, ext_method: 'os_major_version_search', only_explicit: true,
                  operators: %i[eq ne]

    scope :os_major_version, lambda { |major, equals = true|
      where(os_major_version_query(major, equals))
    }

    sortable_by :title
    sortable_by :version, SORT_BY_VERSION
    sortable_by :os_major_version, SORT_BY_OS_MAJOR_VERSION

    def os_major_version
      ref_id[/(?<=RHEL-)\d+/].to_i
    end

    def self.os_major_version_search(_filter, operator, value)
      equals = operator == '=' ? ' ' : ' NOT '
      {
        conditions: "ref_id#{equals}like ?",
        parameter: ["%RHEL-#{value}"]
      }
    end
  end
end
