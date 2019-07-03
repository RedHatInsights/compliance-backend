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
    field :compliant, Boolean, null: false do
      argument :system_id, String, 'Is a system compliant?', required: true
    end

    def compliant(system_id:)
      object.compliant?(Host.find(system_id))
    end
  end
end
