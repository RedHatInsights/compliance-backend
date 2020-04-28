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
      #::CollectionLoader.for(
      #  ::Rule, :rule_references_rules
      #).load(object).then do |rule_references_rules|
      ::RecordLoader.for(
        ::RuleReferencesRule, column: :rule_id, distinct: true, collection: true
      ).load(object.id).then do |rule_references_rules|
        if rule_references_rules.blank?
          [].to_json
        else
          ::RecordLoader.for(
            ::RuleReference, distinct: true
          ).load_many(rule_references_rules).then do |references|
            generate_references_json(references)
          end
        end
      end
    end

    def identifier
      ::CollectionLoader.for(::Rule, :rule_identifier)
                        .load(object).then do |identifier|
        { label: identifier&.label, system: identifier&.system }.to_json
      end
    end

    def profiles
      ::CollectionLoader.for(::Rule, :profiles).load(object).then do |profiles|
        profiles
      end
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
      end.to_json
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
