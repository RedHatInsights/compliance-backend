# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      module Status
        extend Api::V2::Schemas::Util

        STATUS = {
          type: 'object',
          properties: {
            data: {
              type: 'object',
              properties: {
                api: {
                  type: 'boolean',
                  example: true
                }
              }
            }
          }
        }.freeze
      end
    end
  end
end
