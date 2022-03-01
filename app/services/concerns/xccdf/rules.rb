# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def save_rules
        @rules ||= @op_rules.each_with_index.map do |op_rule, idx|
          ::Rule.from_openscap_parser(op_rule, precedence: idx, benchmark_id: @benchmark&.id)
        end

        # This is needed for future computations with rule identifiers
        @new_rules = @rules.select(&:new_record?)

        ::Rule.import!(@rules,
                       on_duplicate_key_update: {
                         conflict_target: %i[ref_id benchmark_id],
                         columns: %i[precedence]
                       })
      end
    end
  end
end
