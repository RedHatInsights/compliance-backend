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
        benchmark: {
          type: 'object',
          required: %w[ref_id title version],
          properties: {
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_benchmark_RHEL-7'
            },
            title: {
              type: 'string',
              example: 'Guide to the Secure Configuration of Red Hat '\
                       'Enterprise Linux 7'
            },
            version: {
              type: 'string',
              example: '0.1.46'
            },
            description: {
              type: 'string'
            }
          }
        },
        profile: {
          type: 'object',
          required: %w[name ref_id],
          properties: {
            name: {
              type: 'string',
              example: 'Standard System Security Profile for Red Hat '\
                       'Enterprise Linux 7'
            },
            ref_id: {
              type: 'string',
              example: 'xccdf_org.ssgproject.content_profile_standard'
            },
            parent_profile_id: {
              type: 'string',
              format: 'uuid',
              nullable: true,
              example: '0105a0f0-7379-4897-a891-f95cfb9ddf9c'
            },
            parent_profile_ref_id: {
              type: 'string',
              nullable: true,
              example: 'xccdf_org.ssgproject.content_profile_standard'
            },
            description: {
              type: 'string',
              nullable: true,
              example: 'This profile contains rules to ensure standard '\
                       'security baseline\nof a Red Hat Enterprise Linux 7 '\
                       'system. Regardless of your system\'s workload\nall of '\
                       'these checks should pass.'
            },
            compliance_threshold: {
              type: 'number',
              example: 95.0
            },
            score: {
              type: 'number',
              example: 63.154762
            },
            business_objective: {
              type: 'string',
              example: 'APAC Expansion',
              nullable: true
            },
            canonical: {
              type: 'boolean',
              example: true
            },
            compliant_host_count: {
              type: 'integer',
              example: 3
            },
            external: {
              type: 'boolean',
              example: false
            },
            tailored: {
              type: 'boolean',
              example: false
            },
            total_host_count: {
              type: 'integer',
              example: 5
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
  Base64.strict_encode64(x_rh_identity.to_json)
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
        'insights': {
          'is_entitled': true
        }
      }
  }.with_indifferent_access
end
# rubocop:enable Metrics/MethodLength

def pagination_params
  parameter name: :limit, in: :query, required: false,
            description: 'The number of items to return',
            schema: { type: :integer, maximum: 100, minimum: 1, default: 10 }
  parameter name: :offset, in: :query, required: false,
            description: 'The number of items to skip before starting '\
            'to collect the result set',
            schema: { type: :integer, minimum: 1, default: 1 }
end

def search_params
  parameter name: :search, in: :query, required: false,
            description: 'Query string compliant with scoped_search '\
            'query language: '\
            'https://github.com/wvanbergen/scoped_search/wiki/Query-language',
            schema: { type: :string, default: '' }
end

def content_types
  consumes 'application/vnd.api+json'
  produces 'application/vnd.api+json'
end

def auth_header
  parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }
end
