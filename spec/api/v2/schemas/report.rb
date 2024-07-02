# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module Report
        extend Api::V2::Schemas::Util

        REPORT = {
          type: :object,
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              enum: ['report'],
              readOnly: true
            },
            title: {
              type: :string,
              examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
              description: 'Short title of the Report',
              readOnly: true
            },
            business_objective: {
              type: :string,
              examples: ['Guide to the Secure Configuration of Red Hat Enterprise Linux 7'],
              description: 'The Business Objective associated to the Policy',
              readOnly: true
            },
            compliance_threshold: {
              type: :number,
              examples: [90],
              maximum: 100,
              minimum: 0,
              description: 'The percentage above which the Policy meets compliance requirements',
              readOnly: true
            },
            os_major_version: {
              type: :number,
              minimum: 6,
              examples: [7],
              description: 'Major version of the Operating System that the Report covers',
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
              description: 'Title of the associated Profile',
              readOnly: true
            },
            assigned_system_count: {
              type: :number,
              minium: 1,
              examples: [42],
              description: 'The number of Systems assigned to this Report. Not visible under the Systems endpoint.',
              readOnly: true
            },
            compliant_system_count: {
              type: :number,
              minium: 0,
              examples: [21],
              description: 'The number of compliant Systems in this Report. Inconsistent under the Systems endpoint.',
              readOnly: true
            },
            all_systems_exposed: {
              type: :boolean,
              description: 'Informs if the user has access to all the Systems under the Report. \
                            Inconsistent under the Systems endpoint.',
              examples: [false],
              readOnly: true
            },
            unsupported_system_count: {
              type: :number,
              minium: 0,
              examples: [3],
              description: 'The number of unsupported Systems in this Report. \
                            Inconsistent under the Systems endpoint.',
              readOnly: true
            },
            reported_system_count: {
              type: :number,
              minium: 0,
              examples: [3],
              description: 'The number of Systems in this Report that have Test Results available. \
                            Inconsistent under the Systems endpoint.',
              readOnly: true
            }
          }
        }.freeze
      end
    end
  end
end
