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
    field :profiles, [::Types::Profile], null: true
    field :identifier, ::Types::RuleIdentifier, null: true
    field :references, [::Types::RuleReference], null: true,
                                                 extras: [:lookahead]
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: true
    end

    def compliant(system_id:)
      object.compliant?(Host.find(system_id))
    end

    def references(lookahead:)
      selected_columns = lookahead.selections.map(&:name) &
                         ::RuleReference.column_names.map(&:to_sym)
      object.references.pluck(selected_columns).map do |reference|
        selected_columns.zip([reference].flatten).to_h
      end
    end
  end
end
