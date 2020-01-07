# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.before(:each) do
    stub_request(:get, /#{Settings.rbac_url}/)
      .to_return(status: 200,
                 body: { 'data': [{ 'permission': 'compliance:*:*' }] }.to_json)
  end

  config.swagger_docs = {
    'v1/openapi.json' => {
      swagger: '2.0',
      info: {
        title: 'Cloud Services for RHEL Compliance API V1',
        version: 'v1',
        description: 'This is the API for Cloud Services for RHEL Compliance. '\
        'You can find out more about Red Hat Cloud Services for RHEL at '\
        '[https://cloud.redhat.com/]'\
        '(https://cloud.redhat.com/)'
      },
      paths: {},
      definitions: {
        error: {
          type: 'object',
          required: %w[code detail status title],
          properties: {
            status: {
              type: 'integer',
              description: 'the HTTP status code applicable to this '\
              'problem, expressed as a string value.',
              minimum: 100,
              maximum: 600
            },
            code: {
              type: 'string',
              description: 'an application-specific error code, expressed '\
              'as a string value.'
            },
            title: {
              type: 'string',
              description: 'a short, human-readable summary of the problem '\
              'that SHOULD NOT change from occurrence to occurrence of the '\
              'problem, except for purposes of localization.'
            },
            detail: {
              type: 'string',
              description: 'a human-readable explanation specific to this '\
              'occurrence of the problem. Like title, this field’s value '\
              'can be localized.'
            }
          }
        },
        metadata:
        {
          type: 'object',
          properties: {
            filter: {
              type: 'string',
              example: "name='Standard System Security Profile for Fedora'"
            }
          }
        },
        host: {
          type: 'object',
          required: %w[name account_id],
          properties: {
            name: {
              name: 'string',
              example: 'cloud.redhat.com'
            },
            account_id: {
              type: 'string',
              example: '649cf080-ccce-4c02-ba60-21d046983c7f'
            }
          }
        },
        links:
        {
          type: 'object',
          properties: {
            self: {
              type: 'string',
              example: 'https://compliance.insights.openshift.org/profiles'
            }
          }
        },
        profile: {
          type: 'object',
          required: %w[name ref_id],
          properties: {
            name: {
              type: 'string',
              example: 'Standard System Security Profile for Fedora'
            },
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_profile_standard'
            }
          }
        },
        rule_result: {
          type: 'object',
          required: %w[result],
          properties: {
            result: {
              type: 'string',
              example: 'passed'
            }
          }
        },
        rule: {
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
              example: 'The audit system should collect access events to read '\
              'audit log directory.\nThe following audit rule will assure '\
              'that access to audit log directory are\ncollected.\n-a '\
              'always,exit -F dir=/var/log/audit/ -F perm=r -F auid>=1000'\
              '-F auid!=unset -F key=access-audit-trail\nIf the auditd daemon'\
              'is configured to use the augenrules\nprogram to read audit'\
              ' rules during daemon startup (the default), add the\nrule to'\
              ' a file with suffix .rules in the directory\n'\
              '/etc/audit/rules.d.\nIf the auditd daemon is configured to use'\
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
        }
      }
    }
  }
end

def encoded_header
  Base64.encode64(x_rh_identity.to_json)
end

# Justification: It's mostly hash test data
# rubocop:disable Metrics/MethodLength
def x_rh_identity
  {
    'identity':
    {
      'account_number': '1234',
      'type': 'User',
      'user': {
        'email': 'a@b.com',
        'username': 'a@b.com',
        'first_name': 'a',
        'last_name': 'b',
        'is_active': true,
        'locale': 'en_US'
      },
      'internal': {
        'org_id': '29329'
      }
    },
    'entitlements':
      {
        'smart_management': {
          'is_entitled': true
        }
      }
  }.with_indifferent_access
end
# rubocop:enable Metrics/MethodLength
