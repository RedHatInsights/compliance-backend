# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Metadata
        METADATA = {
          type: 'object',
          properties: {
            filter: {
              type: 'string',
              example: "name='Standard System Security Profile for Fedora'"
            }
          }
        }.freeze

        LINKS = {
          type: 'object',
          properties: {
            self: {
              type: 'string',
              example: 'https://compliance.insights.openshift.org/profiles'
            }
          }
        }.freeze

        TAGS = {
          type: 'array',
          items: {
            type: 'string',
            example: 'insights/environment=production'
          }
        }.freeze
      end
    end
  end
end
