# frozen_string_literal: true

module V2
  # Methods that are related to getting hierarchical structure of rules and rule groups
  module RuleTree
    extend ActiveSupport::Concern

    included do
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
end
