# frozen_string_literal: true

module V2
  # Model for Security Guides
  class SecurityGuide < ApplicationRecord
    # FIXME: clean up after the remodel
    self.primary_key = :id

    has_many :profiles, class_name: 'V2::Profile', dependent: :destroy
    has_many :value_definitions, class_name: 'V2::ValueDefinition', dependent: :destroy
    has_many :rules, class_name: 'V2::Rule', dependent: :destroy
    has_many :rule_groups, class_name: 'V2::RuleGroup', dependent: :destroy

    searchable_by :title, %i[like unlike eq ne in notin]
    searchable_by :version, %i[eq ne in notin]
    searchable_by :ref_id, %i[eq ne in notin]
    searchable_by :os_major_version, %i[eq ne]

    sortable_by :title
    sortable_by :version, version_to_array(arel_table[:version])
    sortable_by :os_major_version

    def self.os_versions
      reselect(:os_major_version).distinct.reorder(:os_major_version).map(&:os_major_version)
    end

    # Builds the hierarchical structure of groups and rules
    def rule_tree
      cached_rules = rules.order(:precedence).select(:id, :rule_group_id).group_by(&:rule_group_id)

      rule_groups.order(:precedence).select(:id, :ancestry).arrange_serializable do |group, children|
        {
          id: group.id,
          type: :rule_group,
          children: children + (cached_rules[group.id]&.map do |rule|
            { id: rule.id, type: :rule }
          end || [])
        }
      end
    end
  end
end
