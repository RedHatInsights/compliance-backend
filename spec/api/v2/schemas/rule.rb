# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module Rule
        extend Api::V2::Schemas::Util

        RULE = {
          type: :object,
          required: %w[ref_id title precedence severity],
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              readOnly: true,
              enum: ['rule']
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_rule_package_tftp_removed'],
              readOnly: true,
              description: 'Identificator of the Rule'
            },
            title: {
              type: :string,
              examples: ['Remove tftp'],
              readOnly: true,
              description: 'Short title of the Rule'
            },
            rationale: {
              type: :string,
              examples: ['It is recommended that TFTP be remvoed, unless there is a specific need ' \
                         'for TFTP (such as a boot server). In that case, use extreme caution when ' \
                         'configuring the services.'],
              readOnly: true,
              description: 'Rationale of the Rule'
            },
            description: {
              type: :string,
              examples: ['Trivial File Transfer Protocol (TFTP) is a simple file transfer protocol, ' \
                         'typically used to automatically transfer configuration or boot files between ' \
                         'machines. TFTP does not support authentication and can be easily hacked. The ' \
                         'package tftp is a client program that allows for connections to a tftp server.'],
              readOnly: true,
              description: 'Longer description of the Rule'
            },
            precedence: {
              type: 'integer',
              examples: [3],
              readOnly: true,
              description: 'The original sorting precedence of the Rule in the Security Guide'
            },
            severity: {
              type: 'string',
              examples: ['low'],
              readOnly: true,
              description: 'The severity of the Rule'
            },
            remediation_issue_id: {
              type: %w[string null],
              examples: ['ssg:rhel6|rht-ccp|xccdf_org.ssgproject.content_rule_sshd_disable_rhosts'],
              readOnly: true,
              description: 'The idenfitier of the remediation associated to this rule, only available ' \
                           'under profiles.'
            }
          }
        }.freeze
      end
    end
  end
end
