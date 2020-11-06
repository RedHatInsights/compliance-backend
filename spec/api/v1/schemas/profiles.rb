# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Profiles
        extend Api::V1::Schemas::Util

        PROFILE = {
          type: 'object',
          required: %w[parent_profile_id],
          properties: {
            name: {
              type: 'string',
              example: 'my custom profile'
            },
            parent_profile_id: {
              type: 'string',
              format: 'uuid',
              nullable: true,
              example: '0105a0f0-7379-4897-a891-f95cfb9ddf9c',
              required: true
            },
            parent_profile_ref_id: {
              type: 'string',
              nullable: true,
              example: 'xccdf_org.ssgproject.content_profile_standard'
            },
            description: {
              type: 'string',
              nullable: true,
              example: 'This profile contains rules to ensure standard '\
              'security baseline\nof a Red Hat Enterprise Linux 7 '\
              'system. Regardless of your system\'s workload\nall '\
              'of these checks should pass.'
            },
            compliance_threshold: {
              type: 'number',
              example: 95.0
            },
            score: {
              type: 'number',
              example: 63.154762
            },
            business_objective: {
              type: 'string',
              example: 'APAC Expansion',
              nullable: true
            },
            canonical: {
              type: 'boolean',
              example: true
            },
            compliant_host_count: {
              type: 'integer',
              example: 3
            },
            external: {
              type: 'boolean',
              example: false
            },
            tailored: {
              type: 'boolean',
              example: false
            },
            policy_profile_id: {
              type: 'uuid',
              example: '374399b7-e6ba-49b7-a405-9b620a2bd0b3'
            },
            total_host_count: {
              type: 'integer',
              example: 5
            },
            os_major_version: {
              type: 'string',
              example: '7'
            },
            policy_type: {
              type: 'string',
              example: 'Australian Cyber Security Centre (ACSC) Essential Eight'
            }
          }
        }.freeze

        PROFILE_RELATIONSHIPS = {
          type: :object,
          properties: {
            account: ref_schema('relationship'),
            benchmark: ref_schema('relationship'),
            parent_profile: ref_schema('relationship'),
            rules: ref_schema('relationship_collection'),
            hosts: ref_schema('relationship_collection'),
            test_results: ref_schema('relationship_collection')
          }
        }.freeze
      end
    end
  end
end
