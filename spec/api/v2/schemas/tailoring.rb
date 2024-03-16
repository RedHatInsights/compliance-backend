# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module Tailoring
        extend Api::V2::Schemas::Util

        TAILORING = {
          type: :object,
          required: %w[profile_id os_minor_version],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              readOnly: true,
              enum: ['tailoring']
            },
            profile_id: {
              type: :string,
              examples: ['cde8be06-74bc-4a2d-9e7f-11d30c5ea588'],
              readOnly: true,
              description: 'Identificator of the Profile from which the Tailoring was cloned'
            },
            os_major_version: {
              type: :number,
              examples: [7],
              readOnly: true,
              description: 'Major version of the Operating System that the Tailoring covers'
            },
            os_minor_version: {
              type: :number,
              examples: [1],
              readOnly: true,
              description: 'List of the supported Operating System minor versions that ' \
                           'the Tailoring covers'
            },
            value_overrides: {
              type: :object,
              readOnly: true,
              description: 'Pair of keys and values for Value Definition customizations'
            }
          }
        }.freeze
      end
    end
  end
end
