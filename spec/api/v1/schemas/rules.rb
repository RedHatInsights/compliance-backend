# frozen_string_literal: true

module Api
  module V1
    module Schemas
      module Rules
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
            severity: {
              type: 'string',
              example: 'Low'
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
      end
    end
  end
end
