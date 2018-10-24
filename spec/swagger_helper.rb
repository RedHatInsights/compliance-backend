require 'rails_helper'

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you're using the rswag-api to serve API descriptions, you'll need
  # to ensure that it's configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.to_s + '/swagger'

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the 'rswag:specs:to_swagger' rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe '...', swagger_doc: 'v2/swagger.json'
  config.swagger_docs = {
    'v1/swagger.json' => {
      swagger: '2.0',
      info: {
        title: 'Insights Compliance API V1',
        version: 'v1',
        description: 'This is the API for Insights Compliance. You can find out more about Red Hat Insights at [https://access.redhat.com/products/red-hat-insights/](https://access.redhat.com/products/red-hat-insights/)'
      },
      paths: {},
      definitions: {
        error: {
          type: 'object',
          required: ['code', 'detail', 'status', 'title'],
          properties: {
            status: {
              type: 'integer',
              description: 'the HTTP status code applicable to this problem, expressed as a string value.',
              minimum: 100,
              maximum: 600
            },
            code: {
              type: 'string',
              description: 'an application-specific error code, expressed as a string value.'
            },
            title: {
              type: 'string',
              description: 'a short, human-readable summary of the problem that SHOULD NOT change from occurrence to occurrence of the problem, except for purposes of localization.'},
              detail: {
                type: 'string',
                description: 'a human-readable explanation specific to this occurrence of the problem. Like title, this field’s value can be localized.'
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
          required: ['name', 'ref_id'],
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
