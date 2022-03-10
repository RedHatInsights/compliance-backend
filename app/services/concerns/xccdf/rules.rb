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

        @new_rules, @old_rules = @rules.partition(&:new_record?)

        # Import the new records first with validation
        ::Rule.import!(@new_rules, ignore: true)

        # Update the precedence on existing rules, validation is not necessary
        ::Rule.import!(@old_rules,
                      on_duplicate_key_update: {
                        conflict_target: %i[ref_id benchmark_id],
                        columns: %i[precedence]
                      }, validate: false)
      end
    end
  end
end
