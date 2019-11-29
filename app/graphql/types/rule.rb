# frozen_string_literal: true

module Types
  # Definition of the Rule GraphQL type
  class Rule < Types::BaseObject
    graphql_name 'Rule'
    description 'A Rule registered in Insights Compliance'

    field :id, ID, null: false
    field :title, String, null: false
    field :ref_id, String, null: false
    field :rationale, String, null: true
    field :description, String, null: true
    field :severity, String, null: false
    field :remediation_available, Boolean, null: false
    field :profiles, [::Types::Profile], null: true
    field :identifier, ::Types::RuleIdentifier, null: true
    field :references, [::Types::RuleReference], null: true,
                                                 extras: [:lookahead]
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: false
      argument :profile_id, String, 'Is a system compliant with this profile?', required: false
    end

    def compliant(args = {})
      return false unless system_id(args) && profile_id(args)
      RecordLoader.for(::TestResult, column: :host_id, where: { profile_id: profile_id(args) }, order: 'created_at DESC')
        .load(system_id(args)).then do |latest_test_result|
        RecordLoader.for(::RuleResult, column: :test_result_id, where: { rule_id: object.id })
          .load(latest_test_result.id).then do |latest_result|
          #RecordLoader.for(::RuleResult, column: :rule_id).load(object.id).then do |latest_rule_result|
          %w[pass notapplicable notselected].include? latest_result&.result
          #end
        end
      end
    end

    def references(lookahead:)
      CollectionLoader.for(object.class, :rule_references).load(object).then do |references|
        selected_columns = lookahead.selections.map(&:name) &
          ::RuleReference.column_names.map(&:to_sym)
        references.map do |reference|
          selected_columns.zip([reference].flatten).to_h
        end
      end
    end

    private

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end

    def profile_id(args)
      args[:profile_id] || context[:parent_profile_id]
    end
  end
end
