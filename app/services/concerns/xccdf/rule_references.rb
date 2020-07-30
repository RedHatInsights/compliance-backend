# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def save_rule_references
        @rule_references = new_rule_references + existing_rule_references

        ::RuleReference.import!(new_rule_references)
      end

      private

      def new_rule_references
        @new_rule_references ||= new_op_rule_references.map do |op_reference|
          RuleReference.new(href: op_reference.href, label: op_reference.label)
        end
      end

      def existing_rule_references
        @existing_rule_references ||= ::RuleReference
                                      .find_unique(@op_rule_references)
      end

      def existing_href_labels
        existing_rule_references.pluck(:href, :label)
      end

      def new_op_rule_references
        @op_rule_references.reject do |op_reference|
          existing_href_labels.include? [op_reference.href, op_reference.label]
        end
      end
    end
  end
end
