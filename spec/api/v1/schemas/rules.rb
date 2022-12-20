# frozen_string_literal: true

require './spec/api/v1/schemas/util'

module Api
  module V1
    module Schemas
      module Rules
        extend Api::V1::Schemas::Util

        RULE = {
          type: 'object',
          required: %w[title ref_id],
          properties: {
            title: {
              type: 'string',
              example: 'Record Access Events to Audit Log directory'
            },
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_rule_directory_access_'\
              'var_log_audit'
            },
            remediation_issue_id: {
              type: 'string',
              nullable: true,
              example: 'ssg:rhel7|rhelh-stig|xccdf_org.ssgproject.content_'\
              'rule_no_empty_passwords'
            },
            precedence: {
              type: 'integer',
              example: 3
            },
            severity: {
              type: 'string',
              example: 'Low'
            },
            values: {
              type: :array,
              items: {
                type: :string
              },
              examples: %w[uuid1 uuid2]
            },
            description: {
              type: 'string',
              example: 'The audit system should collect access '\
              'audit log directory.\nThe following audit rule will assure '\
              'that access to audit log directory are\ncollected.\n-a '\
              'always,exit -F dir=/var/log/audit/ -F perm=r -F auid>=1000'\
              '-F auid!=unset -F key=access-audit-trail\nIf the'\
              'is configured to use the augenrules\nprogram to read audit'\
              ' rules during daemon startup (the default), add the\nrule to'\
              ' a file with suffix .rules in the directory\n'\
              '/etc/audit/rules.d.\nIf the auditd daemon is to use'\
              ' the auditctl\nutility to read audit rules during daemon '\
              'startup, add the rule to\n/etc/audit/audit.rules file.'
            },
            rationale: {
              type: 'string',
              example: 'Attempts to read the logs should be recorded,'\
              ' suspicious access to audit log files could be an indicator'\
              ' of malicious activity on a system.\nAuditing these events'\
              ' could serve as evidence of potential system compromise.'
            }
          }
        }.freeze

        RULE_RELATIONSHIPS = {
          type: :object,
          properties: {
            benchmark: ref_schema('relationship'),
            rule_identifier: ref_schema('relationship'),
            profiles: ref_schema('relationship_collection')
          }
        }.freeze
      end
    end
  end
end
