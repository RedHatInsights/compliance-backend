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
    field :references, [::Types::RuleReference], null: true
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: false
      argument :profile_id, String, 'Is a system compliant with this profile?', required: false
    end

    def compliant(args = {})
      return false unless system_id(args) && profile_id(args) && context[:rule_results][object.id][profile_id(args)].present?
      #latest_test_result_batch(args).then do |latest_test_result|
        #RecordLoader.for(::RuleResult, column: :test_result_id, where: { rule_id: object.id })
        #  .load(latest_test_result.id).then do |latest_result|
          #RecordLoader.for(::RuleResult, column: :rule_id).load(object.id).then do |latest_rule_result|
      #  latest_result = ::RuleResult.find_by(test_result_id: latest_test_result.id, rule_id: object.id)
        latest_result = context[:rule_results][object.id][profile_id(args)]
        %w[pass notapplicable notselected].include? latest_result
        #end
        #end
      #end
    end

    def references
      #::CollectionLoader.for(::Rule, :rule_references).load(object).then do |rule_references|
      #  rule_references
      #end
      return [] if context[:"rule_references_#{object.id}"].blank?
      ::RecordLoader.for(::RuleReference).load_many(context[:"rule_references_#{object.id}"]).then do |references|
        references
      end
    end

    def identifier
      ::CollectionLoader.for(::Rule, :rule_identifier).load(object).then do |identifier|
        identifier
      end
    end

    private

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end

    def profile_id(args)
      args[:profile_id] || context[:parent_profile_id][object.id]
    end

    def latest_test_result_batch(args)
      ::RecordLoader.for(
        ::TestResult,
        column: :profile_id,
        where: { host_id: system_id(args) },
        order: 'created_at DESC'
      ).load(profile_id(args))
    end
  end
end
