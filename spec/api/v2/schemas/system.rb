# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module System
        extend Api::V2::Schemas::Util

        SYSTEM = {
          type: :object,
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              enum: ['system'],
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
            culled_timestamp: {
              type: :string,
              readOnly: true,
              examples: ['2020-06-04T19:31:55Z']
            },
            stale_timestamp: {
              type: :string,
              readOnly: true,
              examples: ['2020-06-04T19:31:55Z']
            },
            stale_warning_timestamp: {
              type: :string,
              readOnly: true,
              examples: ['2020-06-04T19:31:55Z']
            },
            updated: {
              type: :string,
              readOnly: true,
              examples: ['2020-06-04T19:31:55Z']
            },
            insights_id: ref_schema('id'),
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
            policies: {
              type: :array,
              readOnly: true,
              description: 'List of Policies assigned to the System, visible only ' \
                           'when not listing Systems under a given Policy',
              items: {
                type: :object,
                readOnly: true,
                properties: {
                  id: ref_schema('id'),
                  title: {
                    type: :string,
                    readOnly: true,
                    examples: ['CIS Red Hat Enterprise Linux 7 Benchmark'],
                    description: 'Short title of the Policy'
                  }
                }
              }
            }
          }
        }.freeze
      end
    end
  end
end
