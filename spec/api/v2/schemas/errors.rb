# frozen_string_literal: true

module Api
  module V2
    module Schemas
      module Errors
        ERRORS = {
          type: :object,
          required: ['errors'],
          properties: {
            errors: {
              type: 'array',
              items: {
                type: :string,
                examples: ['V2::SecurityGuide not found with ID a4708198-9d00-4035-bf57-1e7aaad217c5']
              }
            }
          }
        }.freeze
      end
    end
  end
end
