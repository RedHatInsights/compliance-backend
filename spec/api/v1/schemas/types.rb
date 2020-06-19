# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Types
        extend Util

        UUID = { type: :string, format: :uuid }.freeze

        RELATIONSHIP = {
          type: :object,
          properties: {
            data: {
              type: :object,
              properties: {
                id: ref_schema('uuid'),
                type: { type: :string }
              }
            }
          }
        }.freeze

        RELATIONSHIP_COLLECTION = {
          type: :object,
          properties: {
            data: {
              type: :array,
              items: {
                properties: {
                  id: ref_schema('uuid'),
                  type: { type: :string }
                }
              }
            }
          }
        }.freeze
      end
    end
  end
end
