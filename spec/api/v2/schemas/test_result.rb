# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module TestResult
        extend Api::V2::Schemas::Util

        TEST_RESULT = {
          type: :object,
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              enum: ['test_result'],
              readOnly: true
            },
            display_name: {
              type: :string,
              readOnly: true,
              examples: ['localhost'],
              description: 'Display Name of the System'
            },
            groups: {
              type: :array,
              readOnly: true,
              items: {
                type: :object,
                description: 'List of Inventory Groups the System belongs to',
                properties: {
                  id: ref_schema('id'),
                  name: {
                    type: :string,
                    readOnly: true,
                    examples: ['production']
                  }
                }
              }
            },
            tags: {
              type: :array,
              readOnly: true,
              items: {
                type: :object,
                readOnly: true,
                description: 'List of Tags assigned to the System',
                properties: {
                  namespace: {
                    type: :string,
                    readOnly: true,
                    examples: ['insights']
                  },
                  key: {
                    type: :string,
                    readOnly: true,
                    examples: ['environment']
                  },
                  value: {
                    type: :string,
                    readOnly: true,
                    examples: ['production']
                  }
                }
              }
            },
            system_id: {
              type: :string,
              format: :uuid,
              examples: ['e6ba5c79-48af-4899-bb1d-964116b58c7a'],
              readOnly: true,
              description: 'UUID of the underlying System'
            },
            os_major_version: {
              type: :number,
              examples: [7],
              readOnly: true,
              description: 'Major version of the Operating System'
            },
            os_minor_version: {
              type: :number,
              examples: [1],
              readOnly: true,
              description: 'Minor version of the Operating System'
            },
            compliant: {
              type: %w[boolean null],
              examples: [false, true],
              readOnly: true,
              description: 'Whether the Test Result is compliant or not within a given Report.'
            },
            supported: {
              type: %w[boolean null],
              examples: [false, true],
              readOnly: true,
              description: 'Whether the System is supported or not by a Profile within a given Policy.'
            },
            failed_rule_count: {
              type: %w[integer null],
              examples: [3],
              readOnly: true,
              description: 'Number of failed rules in the Test Result'
            },
            last_scanned: {
              type: :string,
              examples: ['2020-06-04T19:31:55Z'],
              readOnly: true,
              description: 'The date when the System has been reported a Test Result for the last time.'
            }
          }
        }.freeze
      end
    end
  end
end
