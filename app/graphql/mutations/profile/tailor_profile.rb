# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to associate rules and groups with a profile
    class TailorProfile < BaseMutation
      include ProfileHelper

      graphql_name 'tailorProfile'

      argument :id, ID, required: true
      argument :rule_ids, [ID], required: false
      argument :rule_ref_ids, [String], required: false
      argument :rule_group_ids, [ID], required: false
      argument :rule_group_ref_ids, [String], required: false
      field :profile, Types::Profile, null: true

      enforce_rbac Rbac::POLICY_WRITE

      def resolve(args = {})
        rules = prepare_entities(:rule, args)
        rule_groups = prepare_entities(:rule_group, args)
        ::Profile.transaction do
          profile = find_profile(args[:id])
          tailor_profile(profile, rules, rule_groups) if profile

          { profile: profile }
        end
      end

      private

      def tailor_profile(profile, rules, rule_groups)
        rules_added, rules_removed = profile.update_rules(**rules)
        rule_groups_added, rule_groups_removed = profile.update_rule_groups(**rule_groups)
        audit_mutation(profile, rules_added, rules_removed, rule_groups_added, rule_groups_removed)
      end

      def audit_mutation(profile, r_added, r_removed, rg_added, rg_removed)
        audit_success(
          "Updated rule and group assignments of profile #{profile.id}," \
          " #{r_added} rules added, #{r_removed} rules removed," \
          " #{rg_added} groups added, #{rg_removed} groups removed"
        )
      end

      def prepare_entities(type, args)
        if args[:"#{type}_ids"]
          { ids: args[:"#{type}_ids"] }
        elsif args[:"#{type}_ref_ids"]
          { ref_ids: args[:"#{type}_ref_ids"] }
        else
          return { ids: nil } if type == :rule_group # FIXME: final cleanup of RHICOMPL-2124

          raise(ActionController::ParameterMissing, "Missing argument identifying #{type.to_s.pluralize}")
        end
      end
    end
  end
end
