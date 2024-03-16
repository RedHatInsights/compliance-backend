# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module SecurityGuide
        extend Api::V2::Schemas::Util

        SECURITY_GUIDE = {
          type: :object,
          required: %w[ref_id title version os_major_version],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              readOnly: true,
              enum: ['security_guide']
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_benchmark_RHEL-7'],
              readOnly: true,
              description: 'Identificator of the Security Guide'
            },
            title: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat Enterprise Linux 7'],
              readOnly: true,
              description: 'Short title of the Security Guide'
            },
            version: {
              type: :string,
              examples: ['0.1.46'],
              readOnly: true,
              description: 'Version of the Security Guide'
            },
            description: {
              type: :string,
              examples: ['This guide presents a catalog of security-relevant ' \
                         'configuration settings for Red Hat Enterprise Linux 7.'],
              readOnly: true,
              description: 'Longer description of the Security Guide'
            },
            os_major_version: {
              type: :number,
              minimum: 6,
              examples: [7],
              readOnly: true,
              description: 'Major version of the Operating System that the Security Guide covers'
            }
          }
        }.freeze
      end
    end
  end
end
