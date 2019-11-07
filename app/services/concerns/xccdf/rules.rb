# frozen_string_literal: true

module Xccdf
  # Methods related to parsing rules
  module Rules
    extend ActiveSupport::Concern

    included do
      def save_rules
        @rules ||= @op_rules.map do |op_rule|
          ::Rule.from_openscap_parser(op_rule, benchmark_id: @benchmark&.id)
        end

        ::Rule.import!(new_rules, ignore: true)
      end

      private

      def new_rules
        @new_rules ||= @rules.select(&:new_record?)
      end
    end
  end
end
