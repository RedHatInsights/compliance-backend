# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleGroupRules
  module RuleGroupRules
    extend ActiveSupport::Concern

    included do
      def save_rule_group_rules
        ::RuleGroupRule.import!(rules_with_rule_group_parent, ignore: true)

        rule_parent_links_to_remove(::RuleGroupRule).delete_all
      end

      private

      def rules_with_rule_group_parent
        @op_rules.flat_map do |op_rule|
          rule_group = rule_group_for(ref_id: op_rule.parent_id)
          next unless rule_group

          rule = rule_for(ref_id: op_rule.id)
          ::RuleGroupRule.new(rule_group: rule_group, rule: rule)
        end.compact
      end

      def rule_parent_links_to_remove(base)
        grouped_by_rgr = rules_with_rule_group_parent.group_by(&:rule_id)
        grouped_by_rgr.reduce(RuleGroupRule.none) do |query, (rule_id, rgr)|
          query.or(
            base.where(rule_id: rule_id)
                .where.not(rule_group_id: rgr.map(&:rule_group_id))
          )
        end
      end
    end
  end
end
