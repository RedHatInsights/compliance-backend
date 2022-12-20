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
    field :profiles, [::Types::Profile], null: true
    field :identifier, GraphQL::Types::JSON, null: true
    field :references, GraphQL::Types::JSON, null: true
    field :values, [ID], null: true
    field :failed_count, Int, null: true
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?',
               required: false
      argument :profile_id, String, 'Is a system compliant with this profile?',
               required: false
    end

    enforce_rbac Rbac::COMPLIANCE_VIEWER

    def compliant(args = {})
      system_id(args) &&
        profile_id(args) &&
        %w[pass notapplicable notselected].include?(
          context[:rule_results][object.id][profile_id(args)]
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

    def profiles
      ::CollectionLoader.for(::Rule, :profiles).load(object).then do |profiles|
        Pundit.policy_scope(context[:current_user], profiles)
      end
    end

    # We only care about this value if there is an attributes cache hit
    def failed_count
      object.attributes['failed_count']
    end

    private

    def system_id(args)
      args[:system_id] || context[:parent_system_id]
    end

    def profile_id(args)
      args[:profile_id] || context[:parent_profile_id][object.id]
    end

    def generate_references_json(references)
      references.compact.map do |ref|
        { href: ref.href, label: ref.label }
      end
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
