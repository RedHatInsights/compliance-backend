# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      # :nodoc:
      module RuleGroup
        extend Api::V2::Schemas::Util

        RULE_GROUP = {
          type: :object,
          properties: {
            id: ref_schema('id'),
            type: {
              type: :string,
              readOnly: true,
              enum: ['rule_group']
            },
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_group_locking_out_password_attempts'],
              readOnly: true,
              description: 'Identificator of the Rule Group'
            },
            title: {
              type: :string,
              examples: ['Set Lockouts for Failed Password Attempt'],
              readOnly: true,
              description: 'Short title of the Rule Group'
            },
            rationale: {
              type: :string,
              examples: ['By limiting the number of failed logon attempts, the risk of ' \
                         'unauthorized system access via user password guessing, otherwise ' \
                         'known as brute-forcing, is reduced. Limits are imposed by locking ' \
                         'the account.'],
              readOnly: true,
              description: 'Rationale of the Rule Group'
            },
            description: {
              type: :string,
              examples: ['The pam_faillock PAM module provides the capability to lock out user ' \
                         'accounts after a number of failed login attempts. Its documentation ' \
                         'is available in /usr/share/doc/pam-VERSION/txts/README.pam_faillock.'],
              readOnly: true,
              description: 'Longer description of the Rule Group'
            },
            precedence: {
              type: 'integer',
              examples: [3],
              readOnly: true,
              description: 'The original sorting precedence of the Rule Group in the Security Guide'
            }
          }
        }.freeze
      end
    end
  end
end
