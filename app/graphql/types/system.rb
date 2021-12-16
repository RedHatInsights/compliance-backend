# frozen_string_literal: true

require_relative 'concerns/system_profiles'

module Types
  # Definition of the System GraphQL type
  class System < Types::BaseObject
    include Concerns::SystemProfiles

    model_class ::Host
    connection_type_class ::Connections::SystemConnection
    graphql_name 'System'
    description 'A System registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :os_major_version, Int, null: true
    field :os_minor_version, Int, null: true
    field :has_policy, Boolean, null: false
    field :culled_timestamp, String, null: false
    field :stale_warning_timestamp, String, null: false
    field :stale_timestamp, String, null: false
    field :insights_id, ID, null: true
    field :profiles, [::Types::Profile], null: true do
      argument :policy_id, ID, 'Filter results by policy or profile ID',
               required: false
    end
    field :test_result_profiles, [::Types::Profile], null: true do
      argument :policy_id, ID,
               'Filter results tested against a policy or profile ID',
               required: false
    end
    field :policies, [::Types::Profile], null: true do
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

    field :tags, [Tag], null: true

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
      context.scoped_set!(:parent_system_id, object.id)
    end
  end
end
