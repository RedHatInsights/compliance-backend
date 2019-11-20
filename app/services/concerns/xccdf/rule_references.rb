# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def save_rule_references
        @rule_references ||= RuleReference.new_from_openscap_parser(
          @op_rule_references
        ).map do |op_reference|
          ::RuleReference.from_openscap_parser(op_reference)
        end

        ::RuleReference.import!(new_rule_references, ignore: true)
      end

      private

      def new_rule_references
        @rule_references.select(&:new_record?)
      end
    end
  end
end
