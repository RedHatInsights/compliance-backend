# frozen_string_literal: true

require './spec/api/v2/schemas/util'

module Api
  module V2
    module Schemas
      module Rules
        extend Api::V2::Schemas::Util

        RULE = {
          type: :object,
          required: %w[ref_id title rationale severity precedence],
          properties: {
            ref_id: {
              type: :string,
              examples: ['xccdf_org.ssgproject.content_rule_file_groupowner_etc_passwd'],
              description: 'Identificator for Rule'
            },
            title: {
              type: :string,
              examples: ['Verify Group Who Owns passwd File'],
              description: 'Brief description of the Rule content'
            },
            description: {
              type: :string,
              examples: ['To properly set the group owner of /etc/passwd, run the command: ' \
              '$ sudo chgrp root /etc/passwd'],
              description: 'Longer description of the Rule content'
            },
            remediation_issue_id: {
              type: :string,
              examples: ['ssg:rhel7|rht-ccp|xccdf_org.ssgproject.content_rule_file_groupowner_etc_passwd'],
              description: 'Identificator used to remediate issues tied to this rule'
            },
            rationale: {
              type: :string,
              examples: ['The /etc/passwd file contains information about the users that are configured on the ' \
              'system. Protection of this file is critical for system security.'],
              description: 'Reasoning for this rule to exist'
            },
            severity: {
              type: :string,
              examples: ['medium'],
              description: 'Level of impact of this Rule'
            },
            precedence: {
              type: :number,
              examples: ['828'],
              description: 'Number of Rule\'s position in the application order'
            }
          }
        }.freeze
      end
    end
  end
end
