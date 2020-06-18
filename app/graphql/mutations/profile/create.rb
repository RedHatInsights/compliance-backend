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
      argument :business_objective_id, String, required: false
      argument :compliance_threshold, Float, required: false
      argument :selected_rule_ref_ids, [String], required: true
      field :profile, Types::Profile, null: false

      def resolve(args = {})
        profile = ::Profile.new(new_profile_options(args))
        profile.save!
        profile.update_rules(ref_ids: args[:selected_rule_ref_ids])
        { profile: profile }
      end

      private

      def new_profile_options(args)
        {
          account_id: context[:current_user].account_id,
          benchmark_id: args[:benchmark_id],
          name: args[:name],
          ref_id: args[:ref_id],
          parent_profile_id: args[:clone_from_profile_id],
          description: args[:description],
          business_objective_id: args[:business_objective_id],
          compliance_threshold: args[:compliance_threshold]
        }
      end
    end
  end
end
