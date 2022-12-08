# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module RuleReferencesContainers
    extend ActiveSupport::Concern

    included do
      def rule_references_containers
        @rule_references_containers = @op_rules.map do |op_rule|
          rule_id = rule_for(ref_id: op_rule.id).id
          ::RuleReferencesContainer.from_openscap_parser(
            op_rule,
            existing: old_rule_references_containers[rule_id],
            rule_id: rule_id
          )
        end
      end

      def save_rule_references_containers
        # Import the new records first with validation
        ::RuleReferencesContainer.import!(new_rule_references_containers, ignore: true)

        # Update the fields on existing rules, validation is not necessary
        ::RuleReferencesContainer.import(old_rule_references_containers.values,
                                         on_duplicate_key_update: {
                                           conflict_target: %i[rule_id],
                                           columns: %i[rule_references]
                                         }, validate: false)
      end

      private

      def old_rule_references_containers
        @old_rule_references_containers ||= ::RuleReferencesContainer.where(
          rule_id: rules.map(&:id)
        ).index_by(&:rule_id)
      end

      def new_rule_references_containers
        @new_rule_references_containers ||= rule_references_containers.select(&:new_record?)
      end
    end
  end
end
