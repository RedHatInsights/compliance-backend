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
    field :identifier, String, null: true
    field :references, String, null: true
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?',
               required: false
      argument :profile_id, String, 'Is a system compliant with this profile?',
               required: false
    end

    def compliant(args = {})
      system_id(args) &&
        profile_id(args) &&
        %w[pass notapplicable notselected].include?(
          context[:rule_results][object.id][profile_id(args)]
        )
    end

    def references
      if context[:"rule_references_#{object.id}"].nil?
        ::CollectionLoader.for(::Rule, :rule_references)
                          .load(object).then do |references|
          references.map { |ref| [ref.href, ref.label] }.to_json
        end
      else
        references_from_context
      end
    end

    def references_from_context
      ::RecordLoader.for(::RuleReference)
                    .load_many(context[:"rule_references_#{object.id}"])
                    .then do |references|
        references.compact.map do |ref|
          { href: ref.href, label: ref.label }
        end.to_json
      end
    end

    def identifier
      ::CollectionLoader.for(::Rule, :rule_identifier)
                        .load(object).then do |identifier|
        { label: identifier&.label, system: identifier&.system }.to_json
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
