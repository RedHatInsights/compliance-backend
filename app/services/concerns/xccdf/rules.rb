# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rules
        @rules ||= @op_rules.each_with_index.map do |op_rule, idx|
          rule_group = rule_group_for(ref_id: op_rule.parent_id)
          value_checks = op_rule.values.map { |value_ref_id| value_definition_for(ref_id: value_ref_id).id }

          ::V2::Rule.from_parser(
            op_rule,
            existing: old_rules[op_rule.id], precedence: idx,
            rule_group_id: rule_group&.id, value_checks: value_checks,
            security_guide_id: security_guide&.id
          )
        end
      end

      def save_rules
        # Import the new records first with validation
        ::V2::Rule.import!(new_rules, ignore: true)

        # Update the fields on existing rules, validation is not necessary
        ::V2::Rule.import(old_rules.values,
                          on_duplicate_key_update: {
                            conflict_target: %i[ref_id security_guide_id],
                            columns: %i[identifier references description precedence rationale
                                        rule_group_id severity value_checks]
                          }, validate: false)
      end

      private

      def new_rules
        @new_rules ||= rules.select(&:new_record?)
      end

      def rule_for(ref_id:)
        @cached_rules ||= @rules.index_by(&:ref_id)
        @cached_rules[ref_id]
      end

      def old_rules
        @old_rules ||= ::V2::Rule.where(
          ref_id: @op_rules.map(&:id), security_guide_id: security_guide&.id
        ).index_by(&:ref_id)
      end
    end
  end
end
