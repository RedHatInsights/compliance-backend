# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def save_rule_references
        @rule_references ||= @op_rule_references.map do |op_reference|
          ::RuleReference.from_openscap_parser(op_reference)
        end

        ::RuleReference.import!(@rule_references.select(&:new_record?),
                                ignore: true)
      end

      def associate_rule_references
        # new_rules.map(&:id) == new_rule_records.pluck(:ref_id)
        new_rule_records.zip(new_rules).each do |rule_record, op_rule|
          references = ::RuleReference.find_from_oscap(op_rule.references)
          rule_record.rule_references = references
        end
      end

      private

      def new_rule_references
        @new_rule_references ||= rule_references.reject(&:persisted?)
      end
    end
  end
end
