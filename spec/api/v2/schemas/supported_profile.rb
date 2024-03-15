# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module SupportedProfile
        extend Api::V2::Schemas::Util

        SUPPORTED_PROFILE = {
          type: :object,
          required: %w[id type ref_id title security_guide_version os_major_version os_minor_versions],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              value: 'supported_profile'
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_profile_cis'],
              description: 'Identificator of the Profile'
            },
            title: {
              type: :string,
              examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
              description: 'Short title of the Profile'
            },
            security_guide_version: {
              type: :string,
              examples: ['0.1.72'],
              description: 'Version of the latest Security Guide supporting this Profile'
            },
            os_major_version: {
              type: :number,
              examples: [7],
              description: 'Major version of the Operating System that the Profile covers'
            },
            os_minor_versions: {
              type: :array,
              items: {
                type: :number,
                examples: [1]
              },
              description: 'List of the supported Operating System minor versions that ' \
                           'the Profile covers'
            }
          }
        }.freeze
      end
    end
  end
end
