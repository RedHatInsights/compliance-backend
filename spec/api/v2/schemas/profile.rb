# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module Profile
        extend Api::V2::Schemas::Util

        PROFILE = {
          type: :object,
          required: %w[id type ref_id title],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              value: 'profile'
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_profile_pci-dss'],
              description: 'Identificator of the Profile'
            },
            title: {
              type: :string,
              examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
              description: 'Short title of the Profile'
            },
            description: {
              type: :string,
              examples: ['This profile defines a baseline that aligns to the Center for Internet Security®' \
              'Red Hat Enterprise Linux 7 Benchmark™, v2.2.0, released 12-27-2017.'],
              description: 'Longer description of the Profile'
            }
          }
        }.freeze
      end
    end
  end
end
