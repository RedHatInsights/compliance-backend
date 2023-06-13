# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module BusinessObjectives
        extend Api::V1::Schemas::Util

        BUSINESS_OBJECTIVE = {
          type: 'object',
          required: %w[title],
          properties: {
            title: {
              type: 'string',
              example: 'Guide to the Secure Configuration of Red Hat ' \
              'Enterprise Linux 7'
            }
          }
        }.freeze

        BUSINESS_OBJECTIVE_RELATIONSHIPS = {
          type: :object,
          properties: {
            profiles: ref_schema('relationship_collection')
          }
        }.freeze
      end
    end
  end
end
