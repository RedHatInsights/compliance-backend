# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def rules
        @rules ||= @op_rules.each_with_index.map do |op_rule, idx|
          rule_group = rule_group_for(ref_id: op_rule.parent_id)

          ::Rule.from_openscap_parser(
            op_rule,
            precedence: idx,
            rule_group_id: rule_group&.id,
            benchmark_id: @benchmark&.id
          )
        end
      end

      def save_rules
        @new_rules, @old_rules = rules.partition(&:new_record?)

        # Import the new records first with validation
        ::Rule.import!(@new_rules, ignore: true)

        # Update the fields on existing rules, validation is not necessary
        ::Rule.import(@old_rules,
                      on_duplicate_key_update: {
                        conflict_target: %i[ref_id benchmark_id],
                        columns: %i[description precedence rationale rule_group_id severity]
                      }, validate: false)
      end
    end
  end
end
