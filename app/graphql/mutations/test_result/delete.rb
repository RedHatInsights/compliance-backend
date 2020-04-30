# frozen_string_literal: true

module Mutations
  module TestResult
    # Mutation to delete a TestResult
    class Delete < BaseMutation
      include Fields

      graphql_name 'deleteTestResults'

      argument :profile_id, ID, required: true
      field :profile, Types::Profile, null: false
      field :test_results, [Types::TestResult], null: false

      def resolve(args = {})
        profile = scoped_profiles.find(args[:profile_id])
        test_results = scoped_test_results(args).destroy_all
        profile.destroy! if profile.external

        { profile: profile, test_results: test_results }
      end

      private

      def scoped_test_results(args = {})
        Pundit.policy_scope(current_user, ::TestResult).where(args)
      end

      def scoped_profiles
        Pundit.policy_scope(current_user, ::Profile)
      end

      def current_user
        context[:current_user]
      end
    end
  end
end
