# frozen_string_literal: true

# Computed Fields of a Profile
module ProfileFields
  extend ActiveSupport::Concern

  included do
    def ssg_version
      benchmark.version
    end

    def policy_type
      (parent_profile || self).name
    end

    def supported_os_versions
      bm_versions.map do |v|
        SupportedSsg.by_ssg_version[v].select { |ssg| ssg.os_major_version == os_major_version }.map do |ssg|
          Gem::Version.new([ssg.os_major_version, ssg.os_minor_version].join('.'))
        end
      end.flatten.uniq.sort.reverse
    end

    def os_major_version
      # Try to reach for this in the cached attributes if possible
      (attributes['os_major_version'] || benchmark&.inferred_os_major_version).to_s
    end

    def os_version
      if os_minor_version.present?
        "#{os_major_version}.#{os_minor_version}"
      else
        os_major_version.to_s
      end
    end

    def canonical?
      parent_profile_id.blank?
    end

    def rules_and_rule_groups
      conflicts = relationships_for('conflicts')
      requires = relationships_for('requires')
      arranged_rule_groups = rule_groups.includes(:rules).arrange_serializable do |parent, children|
        { 'rule_group' => parent, 'group_children' => children,
          'rule_children' => parent.rules_with_relationships(requires, conflicts),
          'requires' => requires[parent], 'conflicts' => conflicts[parent] }
      end

      arranged_rule_groups.concat(rules.without_rule_group_parent.map do |pr|
        { 'rule' => pr, 'requires' => requires[pr], 'conflicts' => conflicts[pr] }
      end)
    end

    private

    def bm_versions
      # Try to reach for this in the cached attributes if possible
      attributes['bm_versions'] || self.class.canonical.where(
        ref_id: ref_id,
        upstream: false
      ).joins(:benchmark).pluck('benchmarks.version')
    end

    def relationships_for(relationship)
      RuleGroupRelationship.with_relationships(rules, relationship).or(
        RuleGroupRelationship.with_relationships(rule_groups, relationship)
      ).each_with_object({}) do |rgr, relationships|
        relationships[rgr.left] ||= []
        relationships[rgr.left] << rgr.right
      end
    end
  end
end
