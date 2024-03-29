# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module ProfileRules
    extend ActiveSupport::Concern

    included do
      def save_profile_rules
        ::ProfileRule.transaction do
          ::ProfileRule.import!(profile_rules,
                                on_duplicate_key_update: {
                                  conflict_target: %i[rule_id profile_id],
                                  columns: %i[rule_id profile_id]
                                })

          base = ::ProfileRule.joins(profile: :benchmark)
                              .where('profiles.parent_profile_id' => nil)

          profile_rule_links_to_remove(base).delete_all
        end
      end

      private

      def profile_rules
        @profile_rules ||= @op_profiles.flat_map do |op_profile|
          profile_id = profile_id_for(ref_id: op_profile.id)
          rule_ids_for(ref_ids: op_profile.selected_rule_ids).map do |rule_id|
            ::ProfileRule.new(
              profile_id: profile_id, rule_id: rule_id
            )
          end
        end
      end

      def profile_rule_links_to_remove(base)
        grouped_rules = profile_rules.group_by(&:profile_id)
        grouped_rules.reduce(ProfileRule.none) do |query, (profile_id, prs)|
          query.or(
            base.where(profile_id: profile_id)
                .where.not(rule_id: prs.map(&:rule_id))
          )
        end
      end

      def profile_id_for(ref_id:)
        @profiles.find { |p| p.ref_id == ref_id }.id
      end

      def rule_ids_for(ref_ids:)
        @rules.select { |r| ref_ids.include?(r.ref_id) }.map(&:id)
      end
    end
  end
end
