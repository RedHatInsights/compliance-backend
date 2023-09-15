# frozen_string_literal: true

module Api
  module V2
    module Schemas
      module Metadata
        UUID = { type: :string, format: :uuid }.freeze

        METADATA = {
          type: :object,
          properties: {
            total: {
              type: :number,
              examples: [1, 42, 770],
              description: 'Total number of items'

            },
            limit: {
              type: :number,
              maximum: 100,
              minimum: 1,
              default: 10,
              examples: [10, 100],
              description: 'Number of items returned per page'
            },
            offset: {
              type: :number,
              minimum: 0,
              default: 0,
              examples: [15, 90],
              description: 'Offset of the first item of paginated response'
            },
            sort_by: {
              type: :string,
              examples: %w[version:asc],
              description: 'Attribute and direction the items are sorted by'
            },
            filter: {
              type: :string,
              default: '',
              examples: ["title='Standard System Security Profile for Fedora'"],
              description: 'Query string used to filter items by their attributes'
            }
          }
        }.freeze

        LINKS = {
          type: :object,
          properties: {
            first: {
              type: :string,
              format: :uri,
              description: 'Link to first page'
            },
            last: {
              type: :string,
              format: :uri,
              description: 'Link to last page'
            },
            previous: {
              type: :string,
              format: :uri,
              description: 'Link to previous page'
            },
            next: {
              type: :string,
              format: :uri,
              description: 'Link to next page'
            }
          }
        }.freeze

        TAGS = {
          type: :array,
          items: {
            type: :string,
            examples: ['insights/environment=production']
          }
        }.freeze
      end
    end
  end
end
