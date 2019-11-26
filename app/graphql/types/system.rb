# frozen_string_literal: true

module Types
  # Definition of the System GraphQL type
  class System < Types::BaseObject
    model_class ::Host
    graphql_name 'System'
    description 'A System registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :profiles, [::Types::Profile], null: true, extras: [:lookahead]
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

    def profiles(lookahead:)
      context_parent(lookahead)
      CollectionLoader.for(object.class, :profiles).load(object).then do |profiles|
        profiles
      end
    end

    def compliant(args = {})
      if args[:profile_id].present?
        RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
          [profile].map { |prof| prof.compliant?(object) }.flatten.all? true
        end
      else
        CollectionLoader.for(object.class, :profiles).load(object).then do |profiles|
          profiles.map { |profile| profile.compliant?(object) }.flatten.all? true
        end
      end
    end

    def profile_names
      CollectionLoader.for(object.class, :profiles).load(object).then do |profiles|
        profiles.pluck(:name).join(', ')
      end
    end

    def rules_passed(args = {})
      return object.rules_passed unless args[:profile_id].present?
      RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
        object.rules_passed(profile)
      end
    end

    def rules_failed(args = {})
      return object.rules_failed unless args[:profile_id].present?
      RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
        object.rules_failed(profile)
      end
    end

    def rule_objects_failed
      ::Rails.cache.fetch("#{object.id}/failed_rule_objects_result",
                          expires_in: 1.week) do
        ::Rule.where(
          id: ::RuleResult.failed.for_system(object.id)
              .includes(:rule).pluck(:rule_id).uniq
        )
      end
    end

    def last_scanned(args = {})
      if args[:profile_id].present?
        RecordLoader.for(::Profile).load(args[:profile_id]).then do |profile|
          rule_ids = profile.rules.pluck(:id)
          # How to pass rule_ids to this collection loader
          CollectionLoader.for(object.class, :rule_results).load(object).then do |rule_results|
            rule_results.where(rule_id: rule_ids).maximum(:end_time)&.iso8601 || 'Never'
          end
        end
      else
        CollectionLoader.for(object.class, :rule_results).load(object).then do |rule_results|
          rule_results.maximum(:end_time)&.iso8601 || 'Never'
        end
      end
    end

    private

    def context_parent(lookahead)
      profile_fields = %i[rulesPassed rulesFailed compliant lastScanned]
      return unless profile_fields.any? { |field| lookahead.selects?(field) }

      context[:parent_system_id] = object.id
    end
  end
end
