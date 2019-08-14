# frozen_string_literal: true

module XCCDFReport
  # Methods related to saving rule references and finding which rules
  # they belong to
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def rule_references
        @rule_references ||= new_rules.flat_map(&:references).uniq
                                      .map do |reference|
          RuleReference.new(reference)
        end
      end

      def save_rule_references
        RuleReference.import(new_rule_references,
                             columns: %i[href label],
                             ignore: true)
      end

      def associate_rule_references
        # new_rules.map(&:id) == new_rule_records.pluck(:ref_id)
        new_rule_records.zip(new_rules).each do |rule_record, oscap_rule|
          references = RuleReference.find_from_oscap(oscap_rule.references)
          rule_record.rule_references = references
        end
      end

      private

      def new_rule_references
        rule_references.keep_if(&:valid?)
      end
    end
  end
end
