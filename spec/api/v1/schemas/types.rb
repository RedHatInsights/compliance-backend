# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Types
        extend Util

        UUID = { type: :string, format: :uuid }.freeze

        RELATIONSHIP = {
          data: {
            id: ref_schema('uuid'),
            type: :string
          }
        }.freeze

        RELATIONSHIP_COLLECTION = {
          data: {
            type: :array,
            items: {
              properties: {
                id: ref_schema('uuid'),
                type: :string
              }
            }
          }
        }.freeze
      end
    end
  end
end
