# frozen_string_literal: true

require './spec/api/v2/schemas'

module Api
  module V2
    class Openapi
      include Api::V2::Schemas

      def self.doc
        new.doc
      end

      def doc
        {
          openapi: '3.1.0',
          info: info,
          servers: servers,
          paths: {},
          components: {
            schemas: SCHEMAS
          }
        }
      end

      def servers
        [
          # TODO: when v1 gets deprecated
          # {
          #   url: 'https://{defaultHost}/api/compliance',
          #   variables: { defaultHost: { default: 'console.redhat.com' } }
          # },
          {
            url: 'https://{defaultHost}/api/compliance/v2',
            variables: { defaultHost: { default: 'console.redhat.com' } }
          }
        ]
      end

      def info
        {
          title: 'Cloud Services for RHEL Compliance API v2',
          version: 'v2',
          description: description
        }
      end

      def description
        'This is the API for Cloud Services for RHEL Compliance. ' \
          'You can find out more about Red Hat Cloud Services for RHEL at ' \
          '[https://console.redhat.com/]' \
          '(https://console.redhat.com/)'
      end
    end
  end
end
