# frozen_string_literal: true

# Methods that are related to getting hierarchical structure of rules and rule groups
module RuleTree
  extend ActiveSupport::Concern

  RULE_ATTRIBUTES = %i[id ref_id].freeze

  RULE_GROUP_ATTRIBUTES = %i[id ref_id title].freeze

  included do
    def rule_tree
      cached_rules = rules.group_by(&:rule_group_id)

      rule_groups.arrange_serializable do |group, children|
        serialize(group, RULE_GROUP_ATTRIBUTES).merge(
          children: children + (cached_rules[group.id]&.map do |rule|
            serialize(rule, RULE_ATTRIBUTES)
          end || [])
        )
      end
    end

    private

    def serialize(item, attrs)
      attrs.each_with_object(type: item.class.to_s.underscore.to_sym) do |key, obj|
        obj[key.to_s.underscore.to_sym] = item[key]
      end
    end
  end
end
