# frozen_string_literal: true

require 'swagger_helper'

describe 'Rules API' do
  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/rules" do
    get 'List all rules' do
      fixtures :rules
      tags 'rule'
      description 'Lists all rules requested'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      operationId 'ListRules'
      parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }

      response '200', 'lists all rules requested' do
        let(:'X-RH-IDENTITY') { encoded_header }
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/definitions/metadata' },
                 links: { '$ref' => '#/definitions/links' },
                 data: {
                   type: :array,
                   items: {
                     properties: {
                       type: { type: :string },
                       id: { type: :string, format: :uuid },
                       attributes: { '$ref' => '#/definitions/rule' }
                     }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          meta: { filter: 'title=Record Access Events to Audit Log directory' },
          data: [
            {
              type: 'Rule',
              id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
              attributes: {
                title: 'Record Access Events to Audit Log directory',
                ref_id: 'xccdf_org.ssgproject.content_rule_directory_access_'\
                'var_log_audit',
                severity: 'Low',
                description: 'The audit system should collect access events to'\
                ' read audit log directory.\nThe following audit rule will '\
                'assure that access to audit log directory are\ncollected.\n-a'\
                ' always,exit -F dir=/var/log/audit/ -F perm=r -F auid>=1000'\
                '-F auid!=unset -F key=access-audit-trail\nIf the auditd '\
                'daemon is configured to use the augenrules\nprogram to read '\
                'audit rules during daemon startup (the default), add '\
                'the\nrule to a file with suffix .rules in the directory\n'\
                '/etc/audit/rules.d.\nIf the auditd daemon is configured to '\
                'use the auditctl\nutility to read audit rules during daemon '\
                'startup, add the rule to\n/etc/audit/audit.rules file.',
                rationale: 'Attempts to read the logs should be recorded,'\
                ' suspicious access to audit log files could be an indicator'\
                ' of malicious activity on a system.\nAuditing these events'\
                ' could serve as evidence of potential system compromise.'
              }
            }
          ]
        }
        run_test!
      end
    end
  end

  path "#{ENV['PATH_PREFIX']}/#{ENV['APP_NAME']}/rules/{id}" do
    get 'Retrieve a rule' do
      set_fixture_class benchmarks: Xccdf::Benchmark
      fixtures :hosts, :benchmarks, :rules, :profiles
      tags 'rule'
      description 'Retrieves data for a rule'
      consumes 'application/vnd.api+json'
      produces 'application/vnd.api+json'
      operationId 'ShowRule'
      parameter name: :'X-RH-IDENTITY', in: :header, schema: { type: :string }
      parameter name: :id, in: :path, type: :string

      response '404', 'rule not found' do
        let(:id) { 'invalid' }
        let(:'X-RH-IDENTITY') { encoded_header }
        examples 'application/vnd.api+json' => {
          errors: 'Resource not found'
        }
        run_test!
      end

      response '200', 'retrieves a rule' do
        let(:'X-RH-IDENTITY') { encoded_header }
        let(:id) do
          Account.create(
            account_number: x_rh_identity[:identity][:account_number]
          )
          user = User.from_x_rh_identity(x_rh_identity[:identity])
          user.save
          profiles(:one).update(account: user.account, hosts: [hosts(:one)])
          rules(:one).update(profiles: [profiles(:one)])
          rules(:one).id
        end
        schema type: :object,
               properties: {
                 meta: { '$ref' => '#/definitions/metadata' },
                 links: { '$ref' => '#/definitions/links' },
                 data: {
                   type: :object,
                   properties: {
                     type: { type: :string },
                     id: { type: :string, format: :uuid },
                     attributes: { '$ref' => '#/definitions/rule' }
                   }
                 }
               }
        examples 'application/vnd.api+json' => {
          data: {
            type: 'Rule',
            id: 'd9654ad0-7cb5-4f61-b57c-0d22e3341dcc',
            attributes: {
              title: 'Record Access Events to Audit Log directory',
              ref_id: 'xccdf_org.ssgproject.content_rule_directory_access_'\
              'var_log_audit',
              severity: 'Low',
              description: 'The audit system should collect access events to '\
              'read audit log directory.\nThe following audit rule will assure'\
              ' that access to audit log directory are\ncollected.\n-a '\
              'always,exit -F dir=/var/log/audit/ -F perm=r -F auid>=1000'\
              '-F auid!=unset -F key=access-audit-trail\nIf the auditd daemon'\
              'is configured to use the augenrules\nprogram to read audit'\
              ' rules during daemon startup (the default), add the\nrule to'\
              ' a file with suffix .rules in the directory\n'\
              '/etc/audit/rules.d.\nIf the auditd daemon is configured to use'\
              ' the auditctl\nutility to read audit rules during daemon '\
              'startup, add the rule to\n/etc/audit/audit.rules file.',
              rationale: 'Attempts to read the logs should be recorded,'\
              ' suspicious access to audit log files could be an indicator'\
              ' of malicious activity on a system.\nAuditing these events'\
              ' could serve as evidence of potential system compromise.'
            }
          }
        }

        run_test!
      end
    end
  end
end
