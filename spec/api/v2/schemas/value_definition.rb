# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module ValueDefinition
        extend Api::V2::Schemas::Util

        VALUE_DEFINITION = {
          type: :object,
          required: %w[id type ref_id title value_type default_value],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              value: 'value_definition'
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_value_var_rekey_limit_size'],
              description: 'Identificator of the Value Definition'
            },
            title: {
              type: :string,
              examples: ['SSH RekeyLimit - size'],
              description: 'Short title of the Value Definition'
            },
            value_type: {
              type: :string,
              examples: ['string'],
              description: 'Type of the Value Definition'
            },
            description: {
              type: :string,
              examples: ['Specify the size component of the rekey limit.'],
              description: 'Longer description of the Value Definition'
            },
            default_value: {
              type: :string,
              examples: ['512M'],
              description: 'Default value of the Value Definition'
            }
          }
        }.freeze
      end
    end
  end
end
