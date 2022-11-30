# frozen_string_literal: true

module Xccdf
  # Methods related to saving groups
  module RuleGroups
    extend ActiveSupport::Concern

    included do
      def save_rule_groups
        @rule_groups ||= @op_rule_groups.map do |op_rule_group|
          ::RuleGroup.from_openscap_parser(op_rule_group,
                                           existing: old_rule_groups[op_rule_group.id],
                                           benchmark_id: @benchmark&.id)
        end

        ::RuleGroup.import!(new_rule_groups, ignore: true)

        # Overwite a superset of old_rule_groups because the IDs of the ancestors are not
        # available in the first import! above
        ::RuleGroup.import(rule_groups_with_ancestry, on_duplicate_key_update: {
                             conflict_target: %i[ref_id benchmark_id],
                             columns: %i[description rationale ancestry]
                           }, validate: false)
      end

      private

      def new_rule_groups
        @new_rule_groups ||= @rule_groups.select(&:new_record?)
      end

      def old_rule_groups
        @old_rule_groups ||= ::RuleGroup.where(
          ref_id: @op_rule_groups.map(&:id), benchmark: @benchmark&.id
        ).index_by(&:ref_id)
      end

      def rule_groups_with_ancestry
        @op_rule_groups.map do |op_rule_group|
          group = rule_group_for(ref_id: op_rule_group.id)

          # Setting up the ancestry column on the rule groups which should contain all
          # ancestor rule_group ids in a string separated by a '/'
          group.ancestry = op_rule_group.parent_ids.map do |parent_ref_id|
            rule_group_for(ref_id: parent_ref_id).id
          end.join('/')

          group
        end
      end

      def rule_group_for(ref_id:)
        @cached_rule_groups ||= @rule_groups.index_by(&:ref_id)
        @cached_rule_groups[ref_id]
      end
    end
  end
end
