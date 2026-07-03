# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule fixes
  module Fixes
    extend ActiveSupport::Concern

    included do
      def fixes
        @fixes ||= rules.flat_map do |rule|
          rule.op_source.fixes.map do |op_fix|
            existing = old_fixes[rule.id + '__' + op_fix.system]
            ::Fix.from_parser(op_fix, existing: existing, rule_id: rule.id, system: op_fix.system)
          end
        end
      end

      def save_fixes
        # Import the new records first with validation
        ::Fix.import!(new_fixes, ignore: true)

        # Update the fields on existing fixes, validation is not necessary
        ::Fix.import(old_fixes.values,
                     on_duplicate_key_update: {
                       conflict_target: %i[rule_id system],
                       columns: %i[strategy disruption complexity text]
                     }, validate: false)
      end

      private

      def new_fixes
        @new_fixes ||= fixes.select(&:new_record?)
      end

      # :nocov:
      def old_fixes
        @old_fixes ||= ::Fix.where(
          rule_id: ::Rule.where(security_guide_id: security_guide&.id)
        ).index_by { |fix| fix.rule_id + '__' + fix.system }
      end
      # :nocov:
    end
  end
end
