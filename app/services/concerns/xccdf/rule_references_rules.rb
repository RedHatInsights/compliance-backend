# frozen_string_literal: true

module Xccdf
  # Methods related to saving RuleReferencesRules
  module RuleReferencesRules
    extend ActiveSupport::Concern

    included do
      def save_rule_references_rules
        @rule_references_rules ||= @op_rules.flat_map do |op_rule|
          rule_references_for(op_rule: op_rule).map do |reference|
            ::RuleReferencesRule
              .find_or_initialize_by(rule_reference_id: reference.id,
                                     rule_id: rule_for(ref_id: op_rule.id).id)
          end
        end

        ::RuleReferencesRule.import!(
          @rule_references_rules.select(&:new_record?), ignore: true
        )
      end

      private

      def rule_references_for(op_rule: nil)
        label_hrefs = op_rule.rule_references.map do |rr|
          [rr.label, rr.href]
        end

        @rule_references.select do |reference|
          label_hrefs.include?([reference.label, reference.href])
        end
      end

      def rule_for(ref_id:)
        @rules.find { |r| r.ref_id == ref_id }
      end
    end
  end
end
