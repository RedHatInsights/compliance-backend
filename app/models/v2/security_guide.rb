# frozen_string_literal: true

module V2
  # Model for Security Guides
  class SecurityGuide < ApplicationRecord
    # FIXME: clean up after the remodel
    self.primary_key = :id

    SORT_BY_VERSION = Arel::Nodes::NamedFunction.new(
      'CAST',
      [
        Arel::Nodes::NamedFunction.new(
          'string_to_array',
          [arel_table[:version], Arel::Nodes::Quoted.new('.')]
        ).as('int[]')
      ]
    )

    has_many :profiles, class_name: 'V2::Profile', dependent: :destroy
    has_many :value_definitions, class_name: 'V2::ValueDefinitions', dependent: :destroy
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy

    scoped_search on: :title, only_explicit: true, operators: %i[like unlike eq ne in notin]
    scoped_search on: %i[version ref_id], only_explicit: true, operators: %i[eq ne in notin]
    scoped_search on: :os_major_version, only_explicit: true, operators: %i[eq ne]

    scope :os_major_version, lambda { |major, equals = true|
      where(os_major_version_query(major, equals))
    }

    sortable_by :title
    sortable_by :version, SORT_BY_VERSION
    sortable_by :os_major_version
  end
end
