# frozen_string_literal: true

require 'rails_helper'

RSpec.configure do |config|
  config.swagger_root = Rails.root.to_s + '/swagger'

  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'Insights Compliance API V1',
        version: 'v1',
        description: 'This is the API for Insights Compliance. '\
        'You can find out more about Red Hat Insights at '\
        '[https://access.redhat.com/products/red-hat-insights/]'\
        '(https://access.redhat.com/products/red-hat-insights/)'
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
        }
      }
    }
  }
end
