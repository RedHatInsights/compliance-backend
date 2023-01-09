# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module ValueDefinitions
        extend Api::V1::Schemas::Util

        VALUE_DEFINITION = {
          type: 'object',
          required: %w[ref_id title],
          properties: {
            name: {
              type: 'string',
              example: 'my custom value_definition'
            },
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_value_var_polipo_session_'\
              'bind_all_unreserved_ports'
            },
            title: {
              type: 'string',
              nullable: true,
              example: 'polipo_session_bind_all_unreserved_ports SELinux Boolean'
            },
            description: {
              type: 'string',
              nullable: true,
              example: 'default - Default SELinux boolean setting. on - SELinux'\
               'boolean is enabled. off - SELinux boolean is disabled.'
            },
            value_type: {
              type: 'string',
              example: 'boolean'
            },
            default_value: {
              type: 'string',
              example: 'true'
            }
          }
        }.freeze

        VALUE_DEFINITION_RELATIONSHIPS = {
          type: :object,
          properties: {
            benchmark: ref_schema('relationship')
          }
        }.freeze
      end
    end
  end
end
