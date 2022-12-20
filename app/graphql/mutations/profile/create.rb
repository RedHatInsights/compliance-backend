# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to create a Profile
    class Create < BaseMutation
      graphql_name 'createProfile'

      argument :clone_from_profile_id, ID, required: true
      argument :business_objective_id, ID, required: false
      argument :benchmark_id, ID, required: true
      argument :name, String, required: true
      argument :ref_id, ID, required: true
      argument :description, String, required: false
      argument :compliance_threshold, Float, required: false
      argument :selected_rule_ref_ids, [String], required: false
      argument :values, GraphQL::Types::JSON, required: false
      field :profile, Types::Profile, null: false

      enforce_rbac Rbac::POLICY_CREATE

      def resolve(args = {})
        policy = new_policy(args)
        profile = new_profile(args)
        rule_changes = create(profile, policy, args[:selected_rule_ref_ids])

        audit_mutation(profile, policy, *rule_changes)
        { profile: profile }
      end

      private

      def create(profile, policy, rule_ref_ids)
        rule_changes = nil
        Policy.transaction do
          policy.save!
          profile.update!(policy: policy, external: false)
          rule_changes = profile.update_rules(ref_ids: rule_ref_ids)
        end
        rule_changes
      end

      def new_policy(args)
        ::Policy.new(new_policy_options(args)).fill_from(
          profile: ::Profile.canonical.find(args[:clone_from_profile_id])
        )
      end

      def new_profile(args)
        ::Profile.new(new_profile_options(args)).fill_from_parent
      end

      def new_policy_options(args)
        {
          account_id: context[:current_user].account_id,
          name: args[:name],
          description: args[:description],
          business_objective_id: args[:business_objective_id],
          compliance_threshold: args[:compliance_threshold]
        }
      end

      def new_profile_options(args)
        {
          account_id: context[:current_user].account_id,
          parent_profile_id: args[:clone_from_profile_id],
          values: ::Profile.prepare_values(args[:values])
        }.compact
      end

      def audit_mutation(profile, policy, rules_added, rules_removed)
        audit_success(
          "Created policy #{policy.id} with initial profile #{profile.id}" \
          ' including tailoring (no systems assigned yet)'
        )

        return unless rules_added&.nonzero? || rules_removed&.nonzero?

        audit_success(
          "Updated tailoring of profile #{profile.id}" \
          " of policy #{profile.policy_id}," \
          " #{rules_added} rules added, #{rules_removed} rules removed"
        )
      end
    end
  end
end
