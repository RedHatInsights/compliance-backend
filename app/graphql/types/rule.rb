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
    field :precedence, Int, null: true
    field :remediation_available, Boolean, null: false
    field :identifier, GraphQL::Types::JSON, null: true
    field :references, GraphQL::Types::JSON, null: true
    field :values, [ID], null: true
    field :failed_count, Int, null: true
    field :compliant, Boolean, null: false

    enforce_rbac Rbac::COMPLIANCE_VIEWER

    def compliant
      system_id && profile_id && %w[pass notapplicable notselected].include?(
        context[:rule_results][object.id][profile_id]
      )
    end

    def references
      # Try to find the references in the current context
      key = :"rule_references_#{object.id}"
      return context[key] if context[key]

      ::CollectionLoader.for(::Rule, :rule_references_container).load(object).then do |rrc|
        rrc&.rule_references
      end
    end

    # We only care about this value if there is an attributes cache hit
    def failed_count
      object.attributes['failed_count']
    end

    private

    def system_id
      context[:parent_system_id]
    end

    def profile_id
      context[:parent_profile_id][object.id]
    end
  end
end
