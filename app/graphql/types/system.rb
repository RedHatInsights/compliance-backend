# frozen_string_literal: true

module Types
  # Definition of the System GraphQL type
  class System < Types::BaseObject
    model_class ::Host
    graphql_name 'System'
    description 'A System registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :profiles, [::Types::Profile], null: true
    field :compliant, Boolean, null: false do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end
    field :profile_names, String, null: false
    field :rules_passed, Int, null: false do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end
    field :rules_failed, Int, null: false do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end
    field :rule_objects_failed, [::Types::Rule], null: true do
      description 'Rules failed by a system'
    end
    field :last_scanned, String, null: true do
      argument :profile_id, String, 'Filter results by profile ID',
               required: false
    end

    def profiles
      context_parent
      object.profiles
    end

    def compliant(args = {})
      profiles = if args[:profile_id].present?
                   [::Profile.find(args[:profile_id])]
                 else
                   object.profiles
                 end

      profiles.map { |profile| profile.compliant?(object) }.flatten.all? true
    end

    def profile_names
      object.profiles.pluck(:name).join(', ')
    end

    def rules_passed(args = {})
      ::Rails.cache.fetch("#{object.id}/#{args[:profile_id]}/rules_passed") do
        ::RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
          object.rules_passed(profile)
        end
      end
    end

    def rules_failed(args = {})
      ::Rails.cache.fetch("#{object.id}/#{args[:profile_id]}/rules_failed") do
        ::RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
          object.rules_failed(profile)
        end
      end
    end

    def rule_objects_failed
      ::Rails.cache.fetch("#{object.id}/failed_rule_objects_result") do
        ::Rule.where(
          id: ::RuleResult.failed.for_system(object.id)
              .includes(:rule).pluck(:rule_id).uniq
        )
      end
    end

    def last_scanned(args = {})
      latest_test_result = ::TestResult.latest.find_by(
        profile_id: args[:profile_id], host_id: object.id
      )
      latest_test_result&.end_time&.iso8601 || 'Never'
    end

    private

    def context_parent
      context[:parent_system_id] = object.id
    end
  end
end
