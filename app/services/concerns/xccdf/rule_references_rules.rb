# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleReferencesRules
  module RuleReferencesRules
    extend ActiveSupport::Concern

    RuleReferencesRuleStruct = Struct.new(:rule_id, :rule_reference_id)

    included do
      def save_rule_references_rules
        @rule_references_rules = new_rule_references_rules +
                                 existing_rule_references_rules

        ::RuleReferencesRule.import!(new_rule_references_rules)
      end

      private

      def op_rule_references_rules
        @op_rule_references_rules ||= @op_rules.flat_map do |op_rule|
          rule = rule_for(ref_id: op_rule.id)
          rule_references_for(op_rule: op_rule).map do |rule_reference|
            RuleReferencesRuleStruct.new(rule.id, rule_reference.id)
          end
        end
      end

      def existing_rule_references_rules
        @existing_rule_references_rules ||= ::RuleReferencesRule.find_unique(
          op_rule_references_rules
        )
      end

      def new_rule_references_rules
        @new_rule_references_rules ||= new_op_rule_references_rules
                                       .map do |op_rule_references_rule|
          RuleReferencesRule.new(
            rule_id: op_rule_references_rule.rule_id,
            rule_reference_id: op_rule_references_rule.rule_reference_id
          )
        end
      end

      def existing_op_rule_references_rules
        existing_rule_references_rules.map do |rule_references_rule|
          RuleReferencesRuleStruct.new(rule_references_rule.rule_id,
                                       rule_references_rule.rule_reference_id)
        end
      end

      def new_op_rule_references_rules
        op_rule_references_rules - existing_op_rule_references_rules
      end

      def rule_references_for(op_rule:)
        @cached_references ||= @rule_references.index_by { |rr| [rr.label, rr.href] }

        op_rule.rule_references.map do |rr|
          @cached_references[[rr.label, rr.href]]
        end.compact
      end

      def rule_for(ref_id:)
        @cached_rules ||= @rules.index_by(&:ref_id)
        @cached_rules[ref_id]
      end
    end
  end
end
