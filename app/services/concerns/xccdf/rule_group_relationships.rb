# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleGroupRelationships
  module RuleGroupRelationships
    extend ActiveSupport::Concern
    included do
      def save_rule_group_relationships
        @op_rules_and_rule_groups = @op_rule_groups + @op_rules

        ::RuleGroupRelationship.import!(
          rule_group_relationships.select(&:new_record?), ignore: true
        )

        rgr_links_to_remove(::RuleGroupRelationship).delete_all
      end

      private

      def rule_group_relationships
        @rule_group_relationships ||= @op_rules_and_rule_groups.flat_map do |op_r_or_rg|
          %i[conflicts requires].flat_map { |type| with_relationship(op_r_or_rg, type) }
        end.compact
      end

      def with_relationship(entity, type)
        left = rule_or_rule_group_for(ref_id: entity.id)
        entity.send(type).map do |relationship_ref_id|
          right = rule_or_rule_group_for(ref_id: relationship_ref_id)
          next unless right

          ::RuleGroupRelationship.find_or_initialize_by(
            left: left, right: right, relationship: type
          )
        end
      end

      def rgr_links_to_remove(base)
        grouped_by_rgr = rule_group_relationships&.group_by(&:left_id)
        grouped_by_rgr&.reduce(RuleGroupRelationship.none) do |query, (left_id, rgr)|
          query.or(
            base.where(left_id: left_id)
                .where.not(right_id: rgr.map(&:right_id))
                .where.not(relationship: rgr.map(&:relationship))
          )
        end
      end

      def rule_or_rule_group_for(ref_id:)
        rule_for(ref_id: ref_id) || rule_group_for(ref_id: ref_id)
      end
    end
  end
end
