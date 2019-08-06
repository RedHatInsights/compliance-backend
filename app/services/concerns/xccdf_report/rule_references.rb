# frozen_string_literal: true

module XCCDFReport
  # Methods related to saving rule references and finding which rules
  # they belong to
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def rule_references
        @rule_references ||= new_rules.map do |rule|
          RuleReference.from_oscap_objects(rule.references)
        end
      end

      def save_rule_references
        RuleReference.import(new_rule_references,
                             columns: %i[href label],
                             ignore: true)
      end

      def associate_rule_references(new_rules)
        new_rules.zip(@rule_references || []).each do |rule, references|
          rule.update(rule_references: references) if references.present?
        end
      end

      private

      def new_rule_references
        rule_references.flatten.keep_if do |rule|
          rule.id.nil?
        end
      end
    end
  end
end
