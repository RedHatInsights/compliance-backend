# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module Policy
        extend Api::V2::Schemas::Util

        POLICY = {
          type: :object,
          required: %w[compliance_threshold policy_id],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              enum: ['policy'],
              readOnly: true
            },
            title: {
              type: :string,
              examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
              description: 'Short title of the Policy'
            },
            description: {
              type: :string,
              examples: ['This profile defines a baseline that aligns to the Center for Internet Security®' \
              'Red Hat Enterprise Linux 7 Benchmark™, v2.2.0, released 12-27-2017.'],
              description: 'Longer description of the Policy'
            },
            business_objective: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat Enterprise Linux 7'],
              description: 'The Business Objective associated to the Policy'
            },
            compliance_threshold: {
              type: :number,
              examples: [90],
              maximum: 100,
              minimum: 0,
              description: 'The percentage above which the Policy meets compliance requirements'
            },
            policy_id: {
              type: :string,
              format: :uuid,
              writeOnly: true,
              examples: ['9c4bccad-eb1f-473f-bd3d-2de6e125f725'],
              description: 'Identifier of the underlying Profile'
            },
            os_major_version: {
              type: :number,
              minimum: 6,
              examples: [7],
              description: 'Major version of the Operating System that the Policy covers',
              readOnly: true
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_profile_pci-dss'],
              description: 'Identificator of the Profile',
              readOnly: true
            },
            profile_title: {
              type: :string,
              examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
              description: 'Title of the associated Policy',
              readOnly: true
            },
            total_system_count: {
              type: :number,
              minium: 0,
              examples: [3],
              description: 'The number of Systems assigned to this Policy',
              readOnly: true
            }
          }
        }.freeze

        POLICY_UPDATE = {
          type: :object,
          properties: {
            description: {
              type: :string,
              examples: ['This profile defines a baseline that aligns to the Center for Internet Security®' \
              'Red Hat Enterprise Linux 7 Benchmark™, v2.2.0, released 12-27-2017.'],
              description: 'Longer description of the Policy'
            },
            business_objective: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat Enterprise Linux 7'],
              description: 'The Business Objective associated to the Policy'
            },
            compliance_threshold: {
              type: :number,
              examples: [90],
              maximum: 100,
              minimum: 0,
              description: 'The percentage above which the Policy meets compliance requirements'
            }
          }
        }.freeze
      end
    end
  end
end
