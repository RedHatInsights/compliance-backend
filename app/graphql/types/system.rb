# frozen_string_literal: true

module Types
  # Definition of the System GraphQL type
  class System < Types::BaseObject
    model_class ::Host
    graphql_name 'System'
    description 'A System registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :os_major_version, Int, null: true
    field :os_minor_version, Int, null: true
    field :profiles, [::Types::Profile], null: true do
      argument :policy_id, ID, 'Filter results by policy or profile ID',
               required: false
    end
    field :rules_passed, Int, null: false do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end
    field :rules_failed, Int, null: false do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end
    field :last_scanned, String, null: true do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end

    def profiles(policy_id: nil)
      context_parent
      all_profiles = object.all_profiles
      all_profiles = all_profiles.in_policy(policy_id) if policy_id
      all_profiles
    end

    def rules_passed(args = {})
      ::RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
        object.rules_passed(profile)
      end
    end

    def rules_failed(args = {})
      ::RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
        object.rules_failed(profile)
      end
    end

    def last_scanned(args = {})
      object.last_scanned(args)
    end

    private

    def context_parent
      context[:parent_system_id] = object.id
    end
  end
end
