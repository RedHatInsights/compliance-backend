# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module SupportedSggs
        extend Api::V1::Schemas::Util

        SUPPORTED_SSG = {
          type: 'object',
          required: %w[package version],
          properties: {
            package: {
              type: 'string',
              example: 'scap-security-guide-0.1.30-5.el7_3'
            },
            version: {
              type: 'string',
              example: '0.1.30'
            },
            os_major_version: {
              type: 'string',
              example: '7'
            },
            os_minor_version: {
              type: 'string',
              example: '3'
            },
            profiles: {
              type: 'array',
              items: {
                type: 'string'
              }
            }
          }
        }.freeze
      end
    end
  end
end
