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
      field :profile, Types::Profile, null: false

      def resolve(args = {})
        original_profile = find_original_profile(args[:clone_from_profile_id])
        profile = ::Profile.new(new_profile_options(args))
        profile.save!
        profile.add_rules_from(profile: original_profile)
        { profile: profile }
      end

      private

      def find_original_profile(profile_id)
        ::Pundit.authorize(
          context[:current_user],
          ::Profile.find(profile_id),
          :show?
        )
      end

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
