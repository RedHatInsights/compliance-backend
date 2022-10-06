# frozen_string_literal: true

module Xccdf
  # Methods related to saving rule references
  module ProfileRuleGroups
    extend ActiveSupport::Concern

    included do
      def save_profile_rule_groups
        ::ProfileRuleGroup.transaction do
          ::ProfileRuleGroup.import!(profile_rule_groups,
                                     on_duplicate_key_update: {
                                       conflict_target: %i[rule_group_id profile_id],
                                       columns: %i[rule_group_id profile_id]
                                     })

          base = ::ProfileRuleGroup.joins(profile: :benchmark)
                                   .where('profiles.parent_profile_id' => nil)

          profile_rule_group_links_to_remove(base).delete_all
        end
      end

      private

      def profile_rule_groups
        @profile_rule_groups ||= @op_profiles.flat_map do |op_profile|
          profile_id = profile_id_for(ref_id: op_profile.id)
          unselected_group_ids = rule_group_ids_for(ref_ids: op_profile.unselected_group_ids)
          @rule_groups.reject { |rg| unselected_group_ids.include?(rg.id) }.map do |rg|
            ::ProfileRuleGroup.new(
              profile_id: profile_id, rule_group_id: rg.id
            )
          end
        end
      end

      def profile_rule_group_links_to_remove(base)
        grouped_rules = profile_rule_groups.group_by(&:profile_id)
        grouped_rules.reduce(ProfileRuleGroup.none) do |query, (profile_id, prs)|
          query.or(
            base.where(profile_id: profile_id)
                .where.not(rule_group_id: prs.map(&:rule_group_id))
          )
        end
      end

      def profile_id_for(ref_id:)
        @profiles.find { |p| p.ref_id == ref_id }.id
      end

      def rule_group_ids_for(ref_ids:)
        @rule_groups.select { |r| ref_ids.include?(r.ref_id) }.map(&:id)
      end
    end
  end
end
