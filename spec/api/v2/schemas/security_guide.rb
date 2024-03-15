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
          required: %w[id type ref_id title version os_major_version],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              value: 'security_guide'
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_benchmark_RHEL-7'],
              description: 'Identificator for Security Guide'
            },
            title: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat Enterprise Linux 7'],
              description: 'Brief description of the Security Guide content'
            },
            version: {
              type: :string,
              examples: ['0.1.46'],
              description: 'Version of Security Guide'
            },
            description: {
              type: :string,
              examples: ['This guide presents a catalog of security-relevant ' \
                         'configuration settings for Red Hat Enterprise Linux 7.'],
              description: 'Longer description of the Security Guide content'
            },
            os_major_version: {
              type: :number,
              minimum: 6,
              examples: [7],
              description: 'Major version of the Operating System that the Security Guide covers'
            }
          }
        }.freeze
      end
    end
  end
end
