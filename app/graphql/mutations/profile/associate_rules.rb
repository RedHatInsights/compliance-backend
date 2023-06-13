# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to associate rules with a profile
    class AssociateRules < BaseMutation
      include ProfileHelper

      graphql_name 'associateRules'

      argument :id, ID, required: true
      argument :rule_ids, [ID], required: false
      argument :rule_ref_ids, [String], required: false
      field :profile, Types::Profile, null: true

      enforce_rbac Rbac::POLICY_WRITE

      def resolve(args = {})
        rules = prepare_rules(args)
        ::Profile.transaction do
          profile = find_profile(args[:id])
          if profile
            rules_added, rules_removed = profile.update_rules(**rules)
            audit_mutation(profile, rules_added, rules_removed)
          end
          { profile: profile }
        end
      end

      private

      def audit_mutation(profile, added, removed)
        audit_success(
          "Updated rule assignments of profile #{profile.id}, " \
          "#{added} rules added, #{removed} rules removed"
        )
      end

      def prepare_rules(args)
        if args[:rule_ids]
          { ids: args[:rule_ids] }
        elsif args[:rule_ref_ids]
          { ref_ids: args[:rule_ref_ids] }
        else
          raise(ActionController::ParameterMissing,
                'Missing argument identifying rules')
        end
      end
    end
  end
end
