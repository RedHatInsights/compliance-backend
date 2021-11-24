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
        # Mark already existing rules to be imported as non-upstream
        # rubocop:disable Rails/SkipsModelValidations
        ::Rule.transaction do
          ::Rule.where(id: old_rules.pluck(:id)).update_all(upstream: false)
        end
        # rubocop:enable Rails/SkipsModelValidations
      end

      private

      def split_rules
        @split_rules ||= @rules.partition(&:new_record?)
      end

      def new_rules
        @new_rules ||= split_rules.first
      end

      def old_rules
        split_rules.last
      end
    end
  end
end
