# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Hosts
        HOST = {
          type: 'object',
          required: %w[name account_id],
          properties: {
            name: {
              type: 'string',
              example: 'cloud.redhat.com'
            },
            account_id: {
              type: 'string',
              example: '649cf080-ccce-4c02-ba60-21d046983c7f'
            }
          }
        }.freeze
      end
    end
  end
end
