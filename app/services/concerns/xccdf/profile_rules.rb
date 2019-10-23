# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module ProfileRules
    extend ActiveSupport::Concern

    included do
      def save_profile_rules
        @profile_rules ||= @op_profiles.flat_map do |op_profile|
          profile_id = profile_id_for(ref_id: op_profile.id)
          rule_ids_for(ref_ids: op_profile.selected_rule_ids).map do |rule_id|
            ::ProfileRule.new(profile_id: profile_id, rule_id: rule_id)
          end
        end

        ::ProfileRule.import!(@profile_rules.select(&:new_record?),
                              ignore: true)
      end

      private

      def profile_id_for(ref_id:)
        @profiles.find { |p| p.ref_id == ref_id }.id
      end

      def rule_ids_for(ref_ids:)
        @rules.select { |r| ref_ids.include?(r.ref_id) }.map(&:id)
      end
    end
  end
end
