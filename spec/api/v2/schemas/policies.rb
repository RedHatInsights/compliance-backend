# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      module Policies
        extend Api::V2::Schemas::Util

        POLICY = {
          type: :object,
          required: %w[title ref_id os_major_version],
          properties: {
            title: {
              type: :string,
              examples: [],
              description: ''
            },
            description: {
              type: :string,
              examples: [],
              decription: ''
            },
            business_objective: {},
            os_major_version: {
              type: :number,
              minimum: SupportedSsg.by_os_major.map(&:first).min.to_i,
              examples: [7],
              description: 'Major version of OS that the Policy is applied to'
            },
            compliance_treshold: {},
            policy_type: {
              type: :string,
              examples: [],
              description: ''
            },
            ref_id: {
              type: :string,
              examples: [],
              description: ''
            },
            host_count: {
              type: :number,
              examples: [300, 42]
            }
          }
        }.freeze
      end
    end
  end
end
