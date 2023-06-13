# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Errors
        ERROR = {
          type: 'object',
          required: %w[code detail status title],
          properties: {
            status: {
              type: 'integer',
              description: 'the HTTP status code applicable to this ' \
              'problem, expressed as a string value.',
              minimum: 100,
              maximum: 600
            },
            code: {
              type: 'string',
              description: 'an application-specific error code, expressed ' \
              'as a string value.'
            },
            title: {
              type: 'string',
              description: 'a short, human-readable summary of the problem ' \
              'that SHOULD NOT change from occurrence to occurrence of the ' \
              'problem, except for purposes of localization.'
            },
            detail: {
              type: 'string',
              description: 'a human-readable explanation specific to this ' \
              'occurrence of the problem. Like title, this field’s value ' \
              'can be localized.'
            }
          }
        }.freeze
      end
    end
  end
end
