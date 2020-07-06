# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module RuleResults
        extend Api::V1::Schemas::Util

        RULE_RESULT = {
          type: 'object',
          required: %w[result],
          properties: {
            result: {
              type: 'string',
              example: 'passed'
            }
          }
        }.freeze

        RULE_RESULT_RELATIONSHIPS = {
          type: :object,
          properties: {
            hosts: ref_schema('relationship_collection'),
            rules: ref_schema('relationship_collection')
          }
        }.freeze
      end
    end
  end
end
