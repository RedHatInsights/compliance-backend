# frozen_string_literal: true

module Mutations
  module Profile
    # Mutation to delete a Profile
    class Delete < BaseMutation
      graphql_name 'deleteProfile'

      argument :id, ID, required: true
      field :profile, Types::Profile, null: false

      def resolve(args = {})
        profile = Pundit.authorize(
          context[:current_user],
          ::Profile.find(args[:id]),
          :destroy?
        )
        profile.destroy!
        { profile: profile }
      end
    end
  end
end
