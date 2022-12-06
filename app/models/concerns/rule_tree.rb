# frozen_string_literal: true

# Methods that are related to getting hierarchical structure of rules and rule groups
module RuleTree
  extend ActiveSupport::Concern

  RULE_ATTRIBUTES = %i[id ref_id title description rationale identifier severity precedence].freeze
  RULE_GROUP_ATTRIBUTES = %i[id ref_id title description rationale].freeze

  included do
    def rule_tree(graphql = false)
      rule_groups.includes(:rules).references(:rules).arrange_serializable do |group, children|
        serialize(group, RULE_GROUP_ATTRIBUTES, graphql).merge(
          children: children + group.rules.map do |rule|
            serialize(rule, RULE_ATTRIBUTES, graphql)
          end
        )
      end
    end

    private

    def serialize(item, attrs, graphql)
      attrs.each_with_object(type: adjust_field(item.class, graphql)) do |key, obj|
        obj[adjust_field(key, graphql)] = item[key]
      end
    end

    def adjust_field(field, graphql)
      (graphql ? field.to_s.camelize(:lower) : field.to_s.underscore).to_sym
    end
  end
end
