# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Status
        extend Api::V1::Schemas::Util

        STATUS = {
          type: 'object',
          properties: { data: {
            api: {
              type: 'boolean',
              example: true
            }
          } }
        }.freeze
      end
    end
  end
end
