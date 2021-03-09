# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to associate rules with a profile
    class AssociateRules < BaseMutation
      include ProfileHelper

      graphql_name 'associateRules'

      argument :id, ID, required: true
      argument :rule_ids, [ID], required: true
      field :profile, Types::Profile, null: true

      def resolve(args = {})
        ::Profile.transaction do
          profile = find_profile(args[:id])
          if profile
            rules_added, rules_removed = profile.update_rules(
              ids: args[:rule_ids]
            )
            audit_mutation(profile, rules_added, rules_removed)
          end
          { profile: profile }
        end
      end

      private

      def audit_mutation(profile, added, removed)
        audit_success(
          "Updated rule assignments of profile #{profile.id}," \
          " #{added} rules added, #{removed} rules removed"
        )
      end
    end
  end
end
