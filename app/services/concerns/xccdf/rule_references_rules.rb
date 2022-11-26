# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleReferencesRules
  module RuleReferencesRules
    extend ActiveSupport::Concern

    included do
      def save_rule_references_rules
        @op_rule_references_rules ||= @op_rules.flat_map do |op_rule|
          rule = rule_for(ref_id: op_rule.id)
          rule_references_for(op_rule: op_rule).map do |rule_reference|
            RuleReferencesRule.new(rule_id: rule.id, rule_reference_id: rule_reference.id)
          end
        end

        ::RuleReferencesRule.import!(@op_rule_references_rules, ignore: true)
      end

      private

      def rule_references_for(op_rule:)
        @cached_references ||= @rule_references.index_by { |rr| [rr.label, rr.href] }

        op_rule.rule_references.map do |rr|
          @cached_references[[rr.label, rr.href]]
        end.compact
      end
    end
  end
end
