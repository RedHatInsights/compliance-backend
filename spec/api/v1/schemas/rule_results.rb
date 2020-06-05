# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module RuleResults
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
      end
    end
  end
end
