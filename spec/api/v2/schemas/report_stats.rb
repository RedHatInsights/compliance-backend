# frozen_string_literal: true

module Api
  module V2
    module Schemas
      # :nodoc:
      module ReportStats
        extend Api::V2::Schemas::Util

        REPORT_STATS = {
          type: :array,
          items: {
            type: :object,
            properties: {
              title: {
                type: :string,
                examples: ['Remove tftp'],
                readOnly: true,
                description: 'Short title of the Rule'
              },
              ref_id: {
                type: :string,
                examples: ['xccdf_org.ssgproject.content_rule_package_tftp_removed'],
                readOnly: true,
                description: 'Identificator of the Rule'
              },
              identifier: {
                type: :object,
                readOnly: true,
                description: 'Identifier of the Rule',
                properties: {
                  label: {
                    type: :string,
                    readOnly: true,
                    examples: ['CCE-80798-2']
                  },
                  system: {
                    type: :string,
                    readOnly: true,
                    examples: ['https://nvd.nist.gov/cce/index.cfm']
                  }
                },
                examples: ['CEE-1234-123']
              },
              severity: {
                type: :string,
                examples: ['low'],
                readOnly: true,
                description: 'The severity of the Rule'
              },
              count: {
                type: 'integer',
                examples: [102],
                readOnly: true,
                description: 'Number of failures'
              }
            }
          }
        }.freeze
      end
    end
  end
end
