# frozen_string_literal: true

module Types
  # Definition of the Profile type in GraphQL
  class Profile < Types::BaseObject
    graphql_name 'Profile'
    description 'A Profile registered in Insights Compliance'

    field :id, ID, null: false
    field :name, String, null: false
    field :description, String, null: true
    field :ref_id, String, null: false
    field :compliance_threshold, Float, null: false
    field :rules, [::Types::Rule], null: true
    field :hosts, [::Types::System], null: true
    field :business_objective, ::Types::BusinessObjective, null: true
    field :business_objective_id, ID, null: true
    field :total_host_count, Int, null: false

    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: true
    end

    field :rules_passed, Int, null: false do
      argument :system_id, String,
               'Rules passed for a system and a profile', required: true
    end

    field :rules_failed, Int, null: false do
      argument :system_id, String,
               'Rules failed for a system and a profile', required: true
    end

    field :last_scanned, String, null: false do
      argument :system_id, String,
               'Last time this profile was scanned for a system', required: true
    end

    field :compliant_host_count, Int, null: false
    def compliant_host_count
      object.hosts.count { |host| object.compliant?(host) }
    end

    def total_host_count
      object.hosts.count
    end

    def compliant(system_id:)
      object.compliant?(Host.find(system_id))
    end

    def rules_passed(system_id:)
      object.results(Host.find(system_id)).count { |result| result }
    end

    def rules_failed(system_id:)
      object.results(Host.find(system_id)).count(&:!)
    end

    def last_scanned(system_id:)
      rule_ids = object.rules.map(&:id)
      rule_results = RuleResult.where(
        rule_id: rule_ids,
        host_id: Host.find(system_id).id
      )
      rule_results.maximum(:end_time)&.iso8601 || 'Never'
    end
  end
end
