# frozen_string_literal: true

module Xccdf
  # Methods related to saving groups
  module RuleGroups
    extend ActiveSupport::Concern

    included do
      def save_rule_groups
        @rule_groups ||= @op_rule_groups.map do |op_rule_group|
          ::RuleGroup.from_openscap_parser(op_rule_group, benchmark_id: @benchmark&.id)
        end

        ::RuleGroup.import!(@rule_groups.select(&:new_record?), ignore: true)
        rule_group_parents
      end

      private

      def rule_group_parents
        @op_rule_groups.each do |op_rule_group|
          rule_group = rule_group_for(ref_id: op_rule_group.id)
          rule_group.update(parent: rule_group_for(ref_id: op_rule_group.parent_id))
        end
      end

      def rule_group_for(ref_id:)
        @cached_rule_groups ||= @rule_groups.index_by(&:ref_id)
        @cached_rule_groups[ref_id]
      end
    end
  end
end
