# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module RuleReferences
    extend ActiveSupport::Concern

    included do
      def save_rule_references
        @rule_references = @op_rule_references.map do |op_rr|
          ::RuleReference.new(href: op_rr.href, label: op_rr.label)
        end

        ::RuleReference.import!(@rule_references,
                                on_duplicate_key_update: {
                                  conflict_target: %i[label href],
                                  columns: %i[label href]
                                })
      end
    end
  end
end
