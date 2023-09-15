# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      module SecurityGuides
        extend Api::V2::Schemas::Util

        SECURITY_GUIDE = {
          type: :object,
          required: %w[ref_id title version os_major_version],
          properties: {
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_benchmark_RHEL-7'],
              description: 'Identificator for Security Guide'
            },
            title: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat ' \
              'Enterprise Linux 7'],
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
              minimum: SupportedSsg.by_os_major.map(&:first).min.to_i,
              examples: [7],
              description: 'Major version of OS that the Security Guide covers'
            }
          }
        }.freeze
      end
    end
  end
end
