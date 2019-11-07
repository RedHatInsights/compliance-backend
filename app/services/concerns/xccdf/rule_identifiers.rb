# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule identifiers
  module RuleIdentifiers
    extend ActiveSupport::Concern

    included do
      def save_rule_identifiers
        @rule_identifiers ||= @new_rules.map do |rule|
          ::RuleIdentifier.from_openscap_parser(rule.op_source.identifier,
                                                rule.id)
        end.compact

        ::RuleIdentifier.import!(new_rule_identifiers, ignore: true)
      end

      private

      def new_rule_identifiers
        @new_rule_identifiers ||= @rule_identifiers.select(&:new_record?)
      end
    end
  end
end
